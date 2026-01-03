# HTTP Client & Headers

## Goal
Prevent “mystery behavior” from global headers while still supporting:
- TMDB requests (bearer token / API key)
- Supabase Edge Function invocations (Authorization bearer + JSON body)
- Pagination + retry for transient errors

## Decision
**Do not** set default headers like `Content-Type: application/json` globally.
Instead:
- set per-request headers based on endpoint requirements
- auth is injected by a dedicated provider

## Recommended design
### Request building
- `HTTPClient.request(_:)` receives:
  - URL
  - method
  - headers (explicit)
  - body (optional)
  - query params

### Auth injection
- `AuthProvider` returns `Authorization` header when required
- Each service chooses whether to attach auth.

## Edge Function calls
- Always send:
  - `Authorization: Bearer <supabase_jwt>`
  - `Content-Type: application/json`
- Include `x-request-id` support if you want to correlate (server already returns one).

## Error handling
- Parse non-2xx bodies (best effort) into:
  - status code
  - message snippet
  - request id header

## Acceptance Criteria
- No global headers are attached by default.
- TMDB + Supabase both work without overriding each other’s needs.
