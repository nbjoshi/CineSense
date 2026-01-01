# CineSense 🍿
**An iOS movie & TV tracker with shareable lists, real-time social features, and AI screenshot-based media identification.**  
Built with **SwiftUI (MVVM)**, **Supabase**, **TMDB**, and **Gemini**.

> **Why CineSense:** Most trackers stop at “watchlist + favorites.” CineSense adds **public share links**, **collaborative lists**, and an **AI-powered “what am I watching?”** flow that identifies media from a screenshot + short user description.

---

## Highlights
- **Auth required** (Supabase magic link + deep link callback)
- **Public sharing via link** (profiles & lists; opt-in)
- **AI screenshot identify** (image + optional text → top candidates)
- **MVVM + Services** architecture
- Consistent UI via a lightweight **Design System**

---

## Features

### Core tracking (TMDB)
- Search movies & TV shows
- Media detail pages (overview, cast, genres, seasons/episodes, trailers, similar media)
- Watchlist, favorites, and custom lists (stored in Supabase)

### Public sharing (link-based)
- Share **profiles** and **lists** publicly via unique links
- Non-users can view shared content (read-only)
- Implemented with **Postgres RPC + RLS**

### Social (planned / WIP)
- Friends, friend requests, blocking
- Shared lists & activity feed
- Group chats (Supabase Realtime): reactions, read receipts, presence

### AI screenshot identify (planned / WIP)
- Upload a screenshot + optional description
- Supabase Edge Function calls **Gemini** to identify likely movie/show/person
- Returns top candidates with confidence + rationale

---

## Tech Stack

### iOS
- SwiftUI
- MVVM + Services
- async/await
- URLSession networking (generic `HTTPClient`)

### Backend
- Supabase Auth
- Supabase Postgres + RLS
- Supabase Storage
- Supabase Edge Functions
- Supabase Realtime (planned)

### APIs
- TMDB (search/discover/details)
- Google Gemini (image+text identification via Edge Function)

---

## Architecture

### MVVM + Services
- **Views**: UI-only (no business logic)
- **ViewModels**: state, user actions, async flows
- **Services**: API + persistence wrappers
