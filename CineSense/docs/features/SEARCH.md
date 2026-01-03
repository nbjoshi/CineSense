# Search

## Goal
Fast search experience with infinite scroll and good empty/error states.

## Requirements
- Search across movie + tv (separate sections or segmented control)
- Infinite scrolling pagination
- Debounce input (e.g. 250–350ms)
- Recent searches stored in SwiftData

## Pagination
- Keep `page` and `total_pages` (TMDB style)
- Trigger next page when user scrolls near end

## Acceptance Criteria
- Paging never duplicates items
- New query resets results + cancels old tasks
