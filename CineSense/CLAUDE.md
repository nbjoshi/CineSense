# CineSense Docs (for Claude Code)

These docs define the architecture, Supabase backend contracts, and feature requirements.

## Quick links
- Architecture
  - `docs/architecture/decisions.md`
  - `docs/architecture/mvvm.md`
  - `docs/architecture/http-client.md`
  - `docs/architecture/navigation-and-ui.md`
- Supabase
  - `docs/supabase/schema.md`
  - `docs/supabase/storage.md`
  - `docs/supabase/edge-functions.md`
- Features
  - `docs/features/home.md`
  - `docs/features/search.md`
  - `docs/features/ai-search.md`
  - `docs/features/discover.md`
  - `docs/features/media-detail.md`
  - `docs/features/profile.md`
  - `docs/features/messaging.md`
  - `docs/features/lists.md`

You are Claude Code acting as a senior iOS + Supabase engineer. You have full access to this repo and will make changes directly. Your job is to implement the CineSense revamp cleanly in small, PR-friendly increments.

CORE PRODUCT CONSTRAINTS
- SwiftUI + MVVM. Views are thin; ViewModels handle state; Services handle IO.
- Tabs are exactly: Home, Search, Lists, Profile.
- Remove default navigation titles; use custom headers (Spotify-like) or none.
- Full-bleed UI: screens should reach the top (safe-area-aware ZStack).
- TMDB calls are client-side in Swift. Supabase Edge Functions are only for AI.
- Split each View into its own file; same for ViewModels and Services.
- Maintain a docs/ folder with markdown describing architecture and backend contracts.

BACKEND REALITY (SUPABASE) — MUST MATCH
- Schema includes enums, triggers, indexes, helper functions, and RLS policies.
- list_items INSERT policy requires:
  - user must be a member (owner/editor/viewer)
  - AND added_by = auth.uid()
  Therefore: the Swift app must always set added_by on insert OR you must add a DB trigger/default to set it.
- list_items currently allows viewer inserts; confirm role semantics. If viewer should be read-only, adjust policy.
- ai_identify edge function request keys are snake_case:
  - image_path
  - text_hint
  Ensure Swift client matches these keys (do not send imagePath/textHint).
- Resolve-share exists; share links point only to PUBLIC targets.

HIGH-PRIORITY GAPS TO ADDRESS (IN PRs)
1) STORAGE POLICIES
- Add explicit Storage policies for:
  - avatars (upload/replace by owner; decide public vs signed-read)
  - ai_uploads (defense-in-depth even if signed URLs are used)
- Document bucket expectations in docs/supabase/storage.md.

2) LIST MEMBERSHIP UX SUPPORT
- Add RLS policy to allow users to leave lists:
  - allow delete where user_id = auth.uid() and role != 'owner' (or allow owner leave only after transferring ownership).
- Add owner-only update policy on list_members so owners can change roles (viewer/editor).
- Update docs to reflect membership rules.

3) AI CONTRACT + CONTENT TYPE CONSISTENCY
- Ensure iOS client sends snake_case keys for ai_identify.
- Reconcile webp mismatch:
  - Either allow webp in ai_identify OR restrict ai_upload_url to jpeg/png only.
- Implement “record selection”:
  - When user selects a candidate, update ai_identify_logs.selected_media_type + selected_tmdb_id (and optionally candidates chosen index).
  - This can be a direct table update (if permitted) or a small RPC.

4) UI/ARCH CLEANUP
- Remove default headers from HTTP client initialization (no global Content-Type/Accept).
- Enforce service-specific headers.
- Split views into individual files.
- Add docs:
  - architecture decisions (tabs, navigation chrome, full-bleed)
  - MVVM guidelines
  - http client rules
  - directory layout

FEATURE IMPLEMENTATION ORDER (SMALL PRs)
PR 1 — Architecture + Docs
- Refactor directory layout (Views/ViewModels/Services/Models/Core).
- HTTP client cleanup (no default headers).
- Add docs in docs/architecture/* and docs/supabase/*.

PR 2 — Tabs + Navigation System
- Implement RootTabView with exactly 4 tabs.
- Remove navigation titles; create reusable Spotify-like header component.
- Ensure swipe back works where appropriate.

PR 3 — Home Rails
- Implement HomeView with rails: recommended, trending, popular, top rated, upcoming, on-air.
- Add filter chips.
- Add skeleton loaders per rail.

PR 4 — Search + Infinite Scroll
- Debounced search across movie/tv.
- Infinite scrolling pagination with clean cancellation behavior.
- Recent searches stored in SwiftData if already planned.

PR 5 — AI Identify UI + Poster Resolution
- Flow:
  1) ai_upload_url -> upload
  2) ai_identify(image_path, text_hint) with snake_case keys
  3) show EXACTLY 5 candidates with skeleton loaders
  4) resolve posters by TMDB search in parallel via TaskGroup
- Implement a strict scoring function:
  - title similarity dominant
  - year match important
  - AI confidence as tie-breaker
- Selecting candidate routes to MediaDetailView(mediaId, mediaType).
- After selection, persist chosen tmdbId/mediaType into ai_identify_logs (update or RPC).

PR 6 — Lists + DB-backed system lists
- Implement system lists:
  - watchlist, favorites, watched
- Back with lists.system_key + list_items.
- Ensure all writes set added_by = auth.uid() or DB auto-sets it.

PR 7 — Media Detail actions + TV progress
- Watchlist/favorite toggles write to DB.
- Share link generation via share_links (and show share sheet).
- TV seasons/episodes + watch_progress.
- Reviews section (create/read, spoilers handling).

PR 8+ — Profile improvements
- Avatar upload, bio, display name edits.
- Public profile toggle.
- Shareable profile links (resolve via share token).

PR 9+ — Messaging (Phase 2)
- Add schema for conversations/messages/attachments, plus realtime.
- Implement friends list + DMs + group chats + image uploads.

DEFINITION OF DONE FOR EACH PR
- Compiles and runs on device/simulator.
- RLS-safe: no writes require service role key from the client.
- All network calls have clear error states + skeleton loading.
- Docs updated to reflect new decisions/constraints.
- Keep PRs small: 1–2 features per PR, incremental commits.

When you need to make a decision not explicitly stated, choose the simplest Spotify-like behavior and document it in docs/architecture/decisions.md.
