# CineSense — API Contracts

All endpoints require an authenticated user (JWT) unless explicitly noted.

## Share Links (DB + RPC, no extra Edge Functions)

Public sharing is supported **only via link/token** (no public in-app discovery).  
Users must be logged in, but the share token functions as a capability to view the shared resource.

### Goals
- Share **public profiles** and **public lists** via tokenized deep links: `cinesense://share/<token>`
- Avoid additional Edge Functions (use Postgres + RLS + RPC)
- Ensure tokens can be revoked/expired
- Ensure private resources cannot be shared by token

---

## Database: `public.share_links`

> NOTE: `share_links` already exists in our schema and contains a `token` UUID used in share URLs.

Key columns:
- `token (uuid)` — share token placed in the URL (must be unique)
- `target_type (enum/user-defined)` — expected values: `'profile'` or `'list'`
- `target_id (uuid)` — points to `profiles.id` OR `lists.id` depending on `target_type`
- `created_by (uuid)` — creator (`auth.uid()`); should default to `auth.uid()` so clients do not supply it
- `expires_at (timestamptz, nullable)` — optional expiration
- `revoked_at (timestamptz, nullable)` — set to revoke token
- `created_at (timestamptz)` — audit

Indexes (recommended):
- `created_by`
- `(target_type, target_id)`
- `unique(token)`

---

## RLS policies for `share_links`

We enable RLS and use a strict insert policy so a user can only create share links for:
- their **own public profile** (`profiles.is_public = true`)
- their **own public list** (`lists.owner_id = auth.uid()` AND `lists.is_public = true`)

We also allow:
- selecting your own created share links (to manage/revoke them)
- updating your own created share links (primarily to set `revoked_at`)

---

## RPC: `public.resolve_share(p_token uuid)`

Purpose:
- Resolve a share token to a share target: `{ target_type, target_id }`
- Validate server-side:
  - token exists
  - not expired (`expires_at` is null OR in the future)
  - not revoked (`revoked_at` is null)
  - target exists and is still public:
    - profile: `profiles.is_public = true`
    - list: `lists.is_public = true`

Response (single row):
```json
{ "target_type": "profile" | "list", "target_id": "<uuid>" }


## Edge Function: ai_upload_url
Purpose: issue signed upload URL for private bucket `ai_uploads`.

### Request
POST /functions/v1/ai_upload_url
Body:
{
  "content_type": "image/jpeg" | "image/png"
}

### Response
200:
{
  "upload_url": "<signed url>",
  "path": "ai_uploads/<userId>/<uuid>.jpg",
  "expires_in": 60
}

Errors:
- 401 unauthenticated
- 400 invalid content type
- 429 rate limited

## Edge Function: ai_identify
Purpose: identify media/person from screenshot.

### Request
POST /functions/v1/ai_identify
Body:
{
  "image_path": "ai_uploads/<userId>/<uuid>.jpg",
  "text_hint": "optional user description",
  "crop_rect": { "x": 0, "y": 0, "w": 1, "h": 1 } // optional normalized
}

### Response
200:
{
  "candidates": [
    {
      "media_type": "movie"|"tv"|"person",
      "tmdb_id": 12345,
      "title": "Inception",
      "year": "2010",
      "confidence": 0.87,
      "rationale": "Matches visual poster + description keywords"
    }
  ],
  "latency_ms": 1320,
  "provider": "gemini",
  "model": "..."
}

Errors:
- 401 unauthenticated
- 413 payload too large / invalid image
- 429 rate limited
- 502 model error (mapped)

## Edge Function: tmdb_proxy (recommended)
Purpose: keep TMDB key out of client + enable caching.

### Request
POST /functions/v1/tmdb_proxy
Body:
{
  "route": "search/multi" | "movie/details" | ...,
  "params": { ... }
}

### Response
200: passthrough JSON (stable wrapper)
{
  "data": { ...tmdb payload... },
  "cached": true|false
}

## Edge Function: share_create
Purpose: create token for a public list/profile.

### Request
POST /functions/v1/share_create
Body:
{
  "target_type": "profile"|"list",
  "target_id": "<uuid>",
  "expires_at": "optional ISO8601"
}

### Response
200:
{
  "token": "<uuid>",
  "url": "cinesense://share/<token>"
}

Errors:
- 403 target is not public
- 404 target not found

## Edge Function or RPC: share_resolve / resolve_share(token)
Purpose: resolve share token to target.

### Request
POST /functions/v1/share_resolve
Body: { "token": "<uuid>" }

### Response
200:
{ "target_type": "profile"|"list", "target_id": "<uuid>" }

Errors:
- 404 token invalid/expired/revoked
