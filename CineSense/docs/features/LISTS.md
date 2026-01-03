# Lists (Spotify-like)

## Goal
Make lists the core “library” experience.

## System lists
- Liked media (favorites)
- Watchlist
- Watched

Backed by `lists.system_key` and `list_items`.

## Custom lists
- User-created lists
- Optional collaborative lists (`is_collaborative` + list_members)

## UX requirements
- Lists tab shows:
  - system lists at top
  - custom lists below
  - collaborative indicator
- List detail:
  - items with sorting
  - notes per item (optional)
  - member management (if collaborative)

## Acceptance Criteria
- Create/edit/delete custom lists
- Add/remove items
- Invite members for collaborative lists (list_members)
