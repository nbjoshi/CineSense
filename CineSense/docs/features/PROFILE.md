# Profile

## Goal
User profile page with editable identity and social sharing.

## Requirements
- Edit:
  - avatar
  - bio
  - display name
  - handle (optional if supported)
- Stats:
  - time watched
  - favorite genres
  - counts: watched/favorites/watchlist
- Reminders:
  - upcoming media reminders (implementation can be local notifications v1)
- Shareable profiles:
  - generate share link via `share_links` targeting profile

## Social hooks
- “Messaging” section lives under Profile tab (see messaging doc)

## Acceptance Criteria
- Profile updates persist to `profiles`
- Avatar upload updates `avatar_url`
- Share link opens profile preview
