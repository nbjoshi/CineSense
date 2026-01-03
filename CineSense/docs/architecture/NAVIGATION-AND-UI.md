# Navigation & UI (Spotify-inspired)

## Tabs
Bottom tabs are exactly:
1) Home
2) Search
3) Lists
4) Profile

## Navigation titles
- Avoid default navigation titles.
- Use custom in-view headers.
- Back behavior:
  - Prefer iOS swipe-back
  - Otherwise show a small back arrow in custom header

## Full-bleed layout
- Screens should visually reach the top of the device.
- Use safe area strategically:
  - allow header/hero to extend into top safe area
  - keep interactive controls inside safe area

## Visual system (guidance)
- Dark mode first.
- Typography hierarchy similar to Spotify:
  - Large bold section headers
  - Subtle secondary labels
- Cards:
  - Media posters with rounded corners
  - Horizontal rails (carousel) for categories
- Skeleton loaders for async content, especially AI candidates (5 at a time).

## Acceptance Criteria
- No “empty gap” above content due to navigation chrome.
- Tabs remain visible and consistent.
- Detail screens feel immersive but navigable.
