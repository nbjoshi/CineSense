# CineSense — Product Spec (v1)

## Summary
CineSense is a SwiftUI iOS app for tracking movies and TV shows that focuses on:
1) frictionless saving (Search + AI Screenshot Identify),
2) collaborative organization (Shared Lists), and
3) public sharing (Public-by-link lists/profiles + public reviews).

Login is required.

## Goals
- Ship a portfolio-grade iOS app with real product polish (performance, states, deep links).
- Demonstrate backend architecture: Supabase RLS, Realtime, Storage, Edge Functions.
- Differentiate from generic trackers via AI Identify + Shared Lists + share links.

## Target Users
People who watch movies/TV and want to:
- track watchlist/favorites/watched,
- keep up with episodes,
- share lists with friends,
- identify movies/people from screenshots.

## Key Differentiators
- AI Screenshot Identify: screenshot + optional text → candidates → save.
- Shared lists: collaborative lists with realtime updates.
- Public-by-link: share a list/profile via link; no internal browsing.

## Authentication
- Required on app launch.
- Sign in with email via Supabase.

## Core Features

### 1) Home
Purpose: reduce decision fatigue and surface next actions.
- Continue Watching (TV progress)
- New episodes for followed shows (phase 2 if you track follow state)
- From your watchlist ("Tonight picks")
- Shared list activity (optional, minimal)

### 2) Search
- Search Movies / TV / People (TMDB)
- Filters: year, genre, sort (minimal)
- AI Identify:
  - Select image + optional crop + optional description
  - Display 3–10 candidates with confidence + short rationale
  - User confirms → save to list

### 3) Discover
Curated shelves (max 4–6):
- Trending (day/week)
- Popular
- Top rated
- Upcoming (movies) / Airing today (TV)

### 4) Lists
- System lists: Watchlist, Favorites, Watched
- Custom lists
- Shared lists section
- Bulk actions (later): reorder, remove, move

### 5) Social (link-sharing only)
- Public profile toggle
- Public list toggle
- Create share link (token)
- Open share link:
  - resolve token → navigate to list/profile
  - if the app is opened cold, route after login

### 6) Media Detail
- Poster/backdrop + title/year
- Actions: Watchlist/Favorite/Wanted/Wrote review/Share
- Sections:
  - Overview, genres, runtime
  - Cast
  - Trailers/clips (phase 2)
  - Similar/recommended
  - Reviews (public reviews in-app)
  - TV: seasons/episodes + progress
  - Where to watch (watch providers, phase 2)

### 7) Reviews (public)
- One review per user per title (v1).
- Report review flow.
- Block user flow.

## Storage Buckets
- `avatars` (public) — profile images
- `ai_uploads` (private) — screenshots used for AI Identify
- (optional) `share_cards` (public) — generated share images

## Edge Functions
- `ai_upload_url` — returns signed upload URL for private `ai_uploads`
- `ai_identify` — reads uploaded image + text hint → calls Gemini → returns candidates
- `share_create` — create share link tokens for public list/profile
- `share_resolve` — resolve share token to target type/id (or use DB RPC)

## Acceptance Criteria

### UX/Quality
- Every screen has loading/empty/error states.
- 60fps scrolling on poster grids and list screens.
- Deep link handling does not crash and routes correctly after login.

### Security
- No Gemini/TMDB secrets in the iOS app.
- AI identify is rate-limited per user.
- RLS prevents access to private lists and memberships.

### AI Identify
- Typical response < 5 seconds.
- Always returns multiple candidates or a clear failure state.
- Never auto-saves; confirmation required.

### Shared Lists
- Two users editing the same list see updates within ~1 second via Realtime.
