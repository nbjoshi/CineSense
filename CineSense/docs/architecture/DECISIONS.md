# Architectural Decisions (ADR-lite)

This file captures decisions Claude Code should treat as constraints.

## 1) MVVM everywhere
**Decision:** SwiftUI views should be thin; state + side-effects live in ViewModels; API/storage live in Services/Repositories.  
**Why:** testability, predictable state, easier feature growth.

## 2) Tabs are fixed (Spotify-like IA)
**Decision:** bottom tabs are exactly: **Home, Search, Lists, Profile**.  
**Why:** aligns to product goal and reduces navigation complexity.

## 3) No visible navigation titles by default
**Decision:** avoid `NavigationStack` titles in top chrome; full-bleed layouts.  
- Use custom headers inside views (Spotify-style) when needed.
- Provide back navigation via:
  - swipe back (default iOS) where possible
  - otherwise a small back arrow in custom header

## 4) Full-bleed vertical layout
**Decision:** views occupy the full vertical space (no extra top padding).  
- Prefer `ZStack` + safe-area-aware overlays.
- Use `.ignoresSafeArea(edges: .top)` selectively for hero/header regions.

## 5) HTTP client: no “default headers” that cause surprises
**Decision:** the HTTP client should NOT set global `Content-Type`, `Accept`, etc. unless required.  
- Headers should be per-request or per-service.
- Auth headers should be injected via an explicit `AuthProvider` or request builder.

## 6) Supabase is system of record for app data
**Decision:** lists, profiles, reviews, messaging, AI logs live in Supabase.  
TMDB remains source of truth for media metadata.

## 7) AI identify uses Edge Functions + Gemini
**Decision:** AI happens server-side in Supabase Edge Functions; app uses signed uploads + function call.

## 8) “Discover” is the home for discovery + AI entry
**Decision:** Discover UX is primarily represented through Home + Search + optional Discover section inside Home (implementation choice),
but service endpoints must exist in `DiscoverService` as a coherent layer.
