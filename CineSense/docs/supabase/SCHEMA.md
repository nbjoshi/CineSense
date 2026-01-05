# Supabase Schema (System of Record)

> This documents the current database shape and how the app should use it.

## Core tables

### profiles
- `id` (uuid, FK `auth.users.id`)
- `handle` (3..24)
- `display_name`
- `bio` (optional)
- `avatar_url` (optional)
- `is_public`

---

### lists
**Represents playlists (custom + system).**

Columns:
- `id` uuid (PK)
- `owner_id` -> `profiles.id` (**NOT NULL**)
- `name` (1..60)
- `description` optional
- `is_public` boolean
- `is_collaborative` boolean
- `system_key` optional enum-like: `watchlist | favorites | watched`
- `created_at` timestamp (default now)
- `updated_at` timestamp (default now; 

Notes:
- “System lists” are normal rows in `lists` with `system_key` set.
- Optional hardening:
  - Unique system list per owner: `UNIQUE (owner_id, system_key) WHERE system_key IS NOT NULL`

---

### list_members
**Who can access a list (sharing/collaboration).**

Columns/constraints:
- composite PK: (`list_id`, `user_id`)
- `list_id` -> `lists.id`
- `user_id` -> `profiles.id`
- `role` default `viewer` (`list_role`)
- `added_by` optional (`profiles.id`)
- `created_at` timestamp (default now)

Behavior:
- If `ON DELETE CASCADE` is enabled on `list_id`, deleting a list deletes its memberships automatically.

---

### list_items
**Items saved in a list (movies / TV shows).**

Columns/constraints:
- `list_id` -> `lists.id`
- `media_type` (`movie | tv`)
- `tmdb_id` bigint > 0
- optional: `added_by`, `note`, `sort_order`
- `created_at` timestamp (default now)
- `updated_at` timestamp (default now; updated via trigger if installed)

Recommended constraints:
- Prevent duplicates within a list:
  - `UNIQUE (list_id, media_type, tmdb_id)` 

Behavior:
- If `ON DELETE CASCADE` is enabled on `list_id`, deleting a list deletes its items automatically. 

Indexes (recommended as data grows):
- `INDEX (list_id, sort_order, created_at)` for fast “open playlist” loads.

---

### reviews
**User-generated reviews tied to TMDB identifiers (not TMDB metadata).**
- `author_id` -> `profiles.id`
- `media_type` (`movie|tv`)
- `tmdb_id` bigint > 0
- rating 0..10 optional
- `title` optional <= 120
- `body` 1..4000
- `contains_spoilers` boolean
- `status` default `active`

---

### watch_progress
Tracks per-episode progress for TV:
- composite PK (`user_id`, `tv_tmdb_id`, `season_number`, `episode_number`)
- watched_at timestamp

---

### share_links
Shareable links for profiles/lists/etc:
- `token` uuid unique
- `created_by` defaults `auth.uid()`
- `target_type` (enum)
- `target_id` uuid
- expires/revoked timestamps

---

### ai_identify_logs
Stores AI identify attempts:
- `user_id`
- `image_sha256`, `text_hint`
- `provider` default `gemini`
- `model`, `latency_ms`, `success`
- `candidates` jsonb
- selected_* fields exist for “which candidate user chose” (optional future wiring)

---

### blocks / reports
Moderation/social scaffolding:
- `blocks(blocker_id, blocked_id)`
- `reports(reporter_id, target_type, target_id, reason, status)`

---

## App usage expectations
- TMDB metadata is **NOT** stored in DB; only identifiers and user-generated content.
- “System lists” (watchlist/favorites/watched) are rows in `lists` with `system_key`.
- `list_items` has **no UUID id column**; items are uniquely identified by `(list_id, media_type, tmdb_id)`.

Swift modeling guidance:
- Model `media_type` and `system_key` as Swift enums with raw string values:
  - `MediaType: String, Codable { case movie, tv }`
  - `SystemKey: String, Codable { case watchlist, favorites, watched }`

Deletion semantics:
- With `ON DELETE CASCADE` on `list_items.list_id` and `list_members.list_id`, deleting a row in `lists` automatically deletes related items and memberships.

---

## Open questions (safe defaults)
- Enums: `media_type`, `list_role`, `report_status`, `review_status`, `target_type` exist as user-defined types.
  App should model these as Swift enums with raw string values.
- `updated_at`:
  - If you want `updated_at` to reflect actual edits, install an `updated_at` trigger (recommended).

---

## Acceptance Criteria
- Can create/read/update:
  - profile
  - system lists + custom lists
  - list membership + items
  - reviews
  - watch progress
  - share links

- Constraints & delete behavior:
  - Cannot add duplicate `(list_id, media_type, tmdb_id)` items to a list
  - Deleting a list removes memberships + items automatically (when cascade enabled)

