# CineSense — Task Backlog (MVVM + Services)

Guiding principle: build vertical slices, not layers. Each task should be ~1–2 hours.

## Milestone 0 — Project scaffolding
1. Create repo layout (ios/ + supabase/ + docs)
   - AC: builds in Xcode, docs exist (SPEC/ARCH/TASKS/API)

2. Add Supabase Swift SDK and create Supabase client provider
   - AC: app compiles; one centralized client initialization

3. Create SessionStore + AuthService
   - AC: session state updates; sign out returns to auth screen

## Milestone 1 — Auth (required login)
4. Sign in with Apple UI + flow (AuthView)
   - AC: user can sign in; session persists on app relaunch

5. Profile bootstrapping
   - AC: after login, profile loads and shows display_name; editing updates profile

## Milestone 2 — Core TMDB slice (Search → Detail → Save)
6. Implement tmdb_proxy edge function (or stub service call)
   - AC: calling tmdb_proxy returns trending results in app

7. SearchView + SearchViewModel + TMDBService
   - AC: debounced search, shows results, loading/empty/error states

8. MediaDetailView + ViewModel
   - AC: shows title/year/overview/poster; handles loading/error

9. ListsService: create/get system lists
   - AC: idempotently ensures watchlist/favorites/watched exist per user

10. Add/remove item to Watchlist/Favorites from detail + results
   - AC: state reflects instantly; persists across relaunch

## Milestone 3 — Lists UX
11. Lists screen (system lists + custom lists)
   - AC: shows list counts; open list → list items view

12. Create custom list
   - AC: create, rename, delete (owner only)

13. Reorder list items (client + persist sort_order)
   - AC: reorder updates and persists

## Milestone 4 — Public-by-link sharing
14. ShareService: share_create
   - AC: generates token and share URL for public list/profile only

15. Deep link handling + pending token after login
   - AC: opening cinesense://share/<token> routes correctly after auth

16. Share resolve + list/profile rendering
   - AC: resolves token and shows correct page; invalid token shows friendly error

## Milestone 5 — Shared lists (Realtime)
17. Make list collaborative (toggle) + invite link (phase 1: manual add via token)
   - AC: second user can join list via token and becomes member

18. Realtime subscription for list_items
   - AC: two devices see adds/removes/reorder within ~1s

19. Member roles and permissions (owner/editor/viewer)
   - AC: viewer can add (or restrict if you choose), editor can reorder/remove, owner can manage members

## Milestone 6 — Public reviews
20. Reviews CRUD (1 per user per media)
   - AC: create/edit/delete review; shows in media detail

21. Report review + block user
   - AC: report inserts; block prevents showing that user’s reviews (client-side filter + server-side future)

## Milestone 7 — AI Identify (signature feature)
22. Storage bucket setup: avatars + ai_uploads + policies
   - AC: upload avatar; can upload screenshot via signed URL

23. Edge: ai_upload_url
   - AC: returns signed upload URL; upload works from iOS

24. Edge: ai_identify (Gemini proxy)
   - AC: given uploaded image path returns candidates; rate limited

25. iOS: AIIdentifyView + results + confirm-save
   - AC: user picks image, sees candidates, confirms one, saves to list

## Milestone 8 — Polish
26. Skeleton loaders, image caching, error UX pass
27. Basic tests (ViewModel state + parsers)
28. App Store readiness: privacy strings, delete account path, settings screen
