# CineSense — API Contracts

All endpoints require an authenticated user (JWT) unless explicitly noted.

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
