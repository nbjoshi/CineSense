# AI Search (Screenshot + Text Hint)

## Goal
User uploads screenshot + optional description; app shows 5 candidate matches with posters, user selects one -> details.

## Flow
1. User selects image (and optional text hint)
2. Call `ai_upload_url` -> upload bytes
3. Call `ai_identify(image_path, text_hint)` -> 5 candidates
4. For each candidate:
   - Call TMDB search (movie or tv) using title + year
   - Choose best match (high confidence threshold)
   - Attach poster URL for display
5. Show candidate cards (5 max) with skeleton loaders while posters resolve
6. Selecting candidate routes to `MediaDetailView(mediaId, mediaType)`

## Caching Behavior
- After a successful identify + poster resolution, cache the final 5 candidates
- Cache key is based on `image_path + text_hint` combination
- On "Identify with AI":
  - If cached candidates exist for the same input, display them immediately and show a "Cached" indicator
  - Show "New AI Search" button to clear cache and rerun the identify flow
  - If no cache exists, show the regular AI identify input view
- Cache is in-memory and persists across AI searches in the same session
- Cache uses LRU eviction (max 50 entries)

## UI Requirements
- Exactly 5 candidates shown
- Skeleton loading while resolving posters
- Each candidate card shows:
  - Poster image
  - Title + year
  - Confidence score
  - 1-sentence rationale
- If cached results exist:
  - Show "Cached" indicator in the header
  - Show "New AI Search" button to clear cache and return to input view
- "New AI Search" button always visible for easy re-identification

## Acceptance Criteria
- Candidate posters appear reliably
- Selection consistently routes to correct detail view
- Cached candidates load without network calls when available
- "New AI Search" clears cache and allows a fresh identify run
- No existing functionality is broken
