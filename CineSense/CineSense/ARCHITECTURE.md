# CineSense — Architecture (MVVM + Services)

## Repo Layout (recommended)
cinesense/
  ios/
    CineSense/
      App/
      Features/
      Core/
      Services/
      Models/
      UIComponents/
      Resources/
    CineSenseTests/
  supabase/
    migrations/
    functions/
  SPEC.md
  ARCHITECTURE.md
  TASKS.md
  API_CONTRACTS.md

## iOS Tech Choices
- SwiftUI
- MVVM + Services
- async/await (no Combine unless needed)
- SwiftData for local cache (phase 2, optional for v1)
- Supabase Swift SDK for Auth/DB/Realtime/Storage

## MVVM Pattern
- View: SwiftUI layout and user interaction.
- ViewModel: state machine (loading/loaded/error), transforms models → UI.
- Service: network/database operations, no UI logic.

### Naming
- Views: `SearchView`, `MediaDetailView`
- ViewModels: `SearchViewModel`, `MediaDetailViewModel`
- Services: `AuthService`, `TMDBService`, `ListsService`, `ReviewsService`, `ShareService`, `AIIdentifyService`

## Data Flow
View → ViewModel → Service → (Supabase Edge Function / Supabase DB / TMDB via proxy) → ViewModel → View

## Core Modules

### App/
- `CineSenseApp.swift` — entry
- `SessionStore.swift` — holds auth session, current user profile, bootstrapping

### Services/
- `SupabaseClientProvider.swift` — single configured client
- `AuthService.swift` — sign-in, sign-out, session refresh
- `ProfileService.swift` — read/update profile
- `ListsService.swift` — CRUD lists, members, items
- `ReviewsService.swift` — CRUD reviews + reporting
- `ShareService.swift` — create/resolve share links
- `StorageService.swift` — avatar upload, ai_upload_url flow
- `AIIdentifyService.swift` — call edge function `ai_identify`
- `TMDBService.swift` — calls `tmdb_proxy` (preferred) or direct TMDB (not recommended)

### Models/
- Domain models: `Profile`, `List`, `ListItem`, `Review`, etc.
- DTOs for network payloads: `AIIdentifyResponse`, `TMDBSearchResponse`

### Core/
- Networking primitives (if needed)
- Error types, Logging, Timeouts, Retry policy
- `AppRouter` / deep link handler

## Supabase: Security & RLS Model
- All tables in `public` have RLS enabled.
- Access rules:
  - Profiles: public profiles visible; self can edit
  - Lists: readable if public OR member; writable if member role permits
  - List membership roster: visible only to members (prevents collaborator leakage)
  - Reviews: public read (active), author write
  - Reports: author can submit & view own reports
  - Share links: only creator can list/manage; resolution via RPC/Edge function

## Storage Buckets
- `avatars` (public): readable by anyone; writes restricted to owner path.
- `ai_uploads` (private): uploads via signed URL; edge function reads with service role; optional TTL cleanup.

## Edge Functions Runtime
- Supabase Edge Functions run on Deno.
- Keep functions stateless and fast.
- Validate JWT for all calls (login required).
- Rate limit AI endpoints per user.

## Deep Links
- Custom scheme: `cinesense://share/<token>`
- Universal link optional later.
- On app open:
  - if not logged in: store pending token and resolve after login
  - if logged in: resolve immediately then route

## Performance Practices
- Image caching (use a solid caching strategy; posters dominate perf)
- Debounced search
- Skeleton placeholders
- Avoid huge JSON decoding on main thread
