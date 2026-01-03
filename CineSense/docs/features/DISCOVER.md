# Discover

## Goal
A coherent “discovery” surface backed by DiscoverService endpoints.

## Requirements
- Implement endpoints in `DiscoverService`
  - trending, popular, top-rated, upcoming, on-air, recommendations (where available)
- Rewrite:
  - DiscoverViewModel
  - DiscoverView
- Integrate Search Bar + AI entry point here (per notes)

## UX
- Search bar pinned near top
- Shortcut buttons:
  - AI identify (camera/upload)
  - Trending / Popular quick filters

## Acceptance Criteria
- DiscoverView uses only DiscoverViewModel state
- No duplicated endpoint logic outside DiscoverService
