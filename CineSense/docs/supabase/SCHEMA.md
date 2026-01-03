# Supabase Schema (System of Record)

> This documents the current database shape and how the app should use it.

## Core tables
### profiles
- `id` (uuid, FK auth.users)
- `handle` (3..24)
- `display_name`
- `bio` (optional)
- `avatar_url` (optional)
- `is_public`

### lists
- `id` uuid
- `owner_id` -> profiles.id
- `name` (1..60)
- `description` optional
- `is_public`
- `is_collaborative`
- `system_key` optional enum-like: `watchlist | favorites | watched`

### list_members
- composite PK (list_id, user_id)
- role default `viewer` (list_role)
- added_by optional

### list_items
- `list_id` -> lists.id
- `media_type` (movie|tv)
- `tmdb_id` bigint > 0
- optional: `added_by`, `note`, `sort_order`

### reviews
- `author_id` -> profiles.id
- `media_type` (movie|tv)
- `tmdb_id` bigint > 0
- rating 0..10 optional
- `title` optional <= 120
- `body` 1..4000
- `contains_spoilers` boolean
- `status` default active

### watch_progress
Tracks per-episode progress for TV:
- composite PK (user_id, tv_tmdb_id, season_number, episode_number)
- watched_at timestamp

### share_links
Shareable links for profiles/lists/etc:
- `token` uuid unique
- `created_by` defaults auth.uid()
- `target_type` (enum)
- `target_id` uuid
- expires/revoked timestamps

### ai_identify_logs
Stores AI identify attempts:
- `user_id`
- `image_sha256`, `text_hint`
- `provider` default gemini
- `model`, `latency_ms`, `success`
- `candidates` jsonb
- selected_* fields exist for “which candidate user chose” (optional future wiring)

### blocks / reports
Moderation/social scaffolding:
- `blocks(blocker_id, blocked_id)`
- `reports(reporter_id, target_type, target_id, reason, status)`

## App usage expectations
- TMDB metadata is NOT stored in DB; only identifiers and user-generated content.
- “System lists” (watchlist/favorites/watched) are rows in `lists` with `system_key`.

## Open questions (safe defaults)
- Enums: `media_type`, `list_role`, `report_status`, `review_status`, `target_type` exist as user-defined types.
  App should model these as Swift enums with raw string values.

## Acceptance Criteria
- Can create/read/update:
  - profile
  - system lists + custom lists
  - list membership + items
  - reviews
  - watch progress
  - share links
