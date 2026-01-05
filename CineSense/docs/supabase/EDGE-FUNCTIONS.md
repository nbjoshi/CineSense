# Edge Function: ai_upload_url

## Purpose
Generate a **signed upload URL** for the `ai_uploads` private bucket.

## Endpoint
POST `/functions/v1/ai_upload_url`

## Auth
Requires `Authorization: Bearer <supabase_jwt>`.

## Request body
```json
{ "content_type": "image/jpeg" | "image/png" | "image/webp" }

## Response body
```json
{
  "upload_url": "https://....",
  "path": "<userId>/<uuid>.<ext>",
  "expires_in": 60  
}

# Edge Function: ai_identify
## Purpose
Given an uploaded screenshot path (in `ai_uploads`) + optional text hint, call Gemini and return exactly **5 candidates**.

## Endpoint
POST `/functions/v1/ai_identify`

## Auth
Requires `Authorization: Bearer <supabase_jwt>`.

## Request body
```json
{
  "image_path": "<userId>/....jpg",
  "text_hint": "optional text up to 500 chars"
}

## Response body
```json
{
  "query_summary": "string",
  "candidates": [
    { "title": "string", "type": "movie|tv", "year": "string", "confidence": 0.0, "rationale": "string" }
  ],
  "provider": "gemini",
  "model": "gemini-...",
  "latency_ms": 1234
}

