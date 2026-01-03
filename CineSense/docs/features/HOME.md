# Home

## Goal
A Spotify-like landing page with multiple horizontal rails.

## IMPORTANT: Search UI Separation
**Home has NO search UI.** Search (text + AI) lives in the dedicated Search tab.
Home is purely a discovery surface with curated rails.

## Content rails
- Recommended for You (personalized later; start with TMDB "popular" proxy)
- Trending Now
- Popular Movies
- Popular TV Shows
- Top Rated (movies + TV combined)
- Coming Soon (upcoming movies)
- On the Air (TV shows currently airing)

## Implementation Details
- **HomeView**: Full-bleed Spotify-style vertical scroll
- **HomeViewModel**: Per-rail state (loading/loaded/empty/error) with parallel TaskGroup fetching
- **Components**:
  - `MediaPosterCard`: Lightweight poster card (120x180) with rounded corners
  - `SectionHeaderView`: Bold section titles
  - `MediaRailView`: Horizontal scrollable rail
  - `RailSkeletonView`: Shimmer loader while fetching
- **Data Source**: DiscoverService endpoints (TMDB client-side)

## UX requirements
- Full-bleed header (no navigation title)
- Scrollable vertical feed of rails
- Skeleton loaders per rail (progressive rendering)
- Tapping a card -> `MediaDetailView(mediaId: Int, mediaType: MediaType)`
- Pull-to-refresh support

## Acceptance Criteria
- Loads quickly (progressive rendering via TaskGroup)
- No navigation title chrome
- Smooth scrolling
- Each rail loads independently (failure in one doesn't block others)
