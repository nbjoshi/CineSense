# Media Detail

## Goal
A rich detail page with user actions and deep content.

## Requirements
### Actions (DB-backed)
- Watchlist
- Favorite
- Share link

### TV-specific
- Seasons + episodes browsing
- Episode cards + mark watched
- Persist progress in `watch_progress`

### Reviews
- Create/read reviews for this media
- Spoiler toggle handling
- Rating optional 0..10

### Watch providers
- Display provider availability (from TMDB watch providers API)

## Data contracts
- Detail view is initialized as:
  `MediaDetailView(mediaId: Int, mediaType: MediaType)`

## Acceptance Criteria
- Toggling watchlist/favorite persists to Supabase (lists/list_items)
- Share generates a share link (share_links)
- TV progress writes to watch_progress
