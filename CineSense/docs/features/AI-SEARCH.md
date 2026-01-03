# AI Search (Screenshot + Text Hint)

## Goal
User uploads screenshot + optional description; app shows 5 candidate matches with posters, user selects one -> details.

## Flow
1) User selects image (and optional text hint)
2) Call `ai_upload_url` -> upload bytes
3) Call `ai_identify(image_path, text_hint)` -> 5 candidates
4) For each candidate:
   - Call TMDB search (movie or tv) using title + year,
   - choose best match (high confidence threshold),
   - attach poster URL for display
5) Show candidate cards (5 max) with skeleton loaders while posters resolve
6) Selecting candidate routes to `MediaDetailView(mediaId, mediaType)`

## UI requirements
- Exactly 5 candidates shown
- Skeleton loading
- Each candidate card shows:
  - poster
  - title + year
  - confidence
  - 1-sentence rationale

## Acceptance Criteria
- Candidate posters appear reliably
- Selection consistently routes to correct detail view
