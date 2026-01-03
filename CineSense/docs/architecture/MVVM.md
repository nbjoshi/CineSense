# MVVM Guidelines (SwiftUI)

## Folder conventions
- **Views**: declarative UI, minimal logic
- **ViewModels**: `@MainActor` observable objects; transforms service data into view state
- **Services**: networking (TMDB, Supabase functions), storage (Supabase tables/buckets)
- **Models**: Codable domain models + UI models
- **Components**: reusable SwiftUI building blocks

## View rules
- No networking in Views.
- No direct Supabase client calls in Views.
- Views bind to a `ViewModel` state:
  - `loading`, `loaded`, `empty`, `error`
- Views receive navigation “IDs” (tmdbId + mediaType) and let the VM load details.

## ViewModel rules
- Mark VMs `@MainActor`.
- Side effects happen in `Task {}` or VM async methods.
- Use cancellation-friendly patterns:
  - store current `Task` and cancel on new request
  - debounce text search input
- Map service errors to user-friendly UI states.

## Service rules
- One responsibility per service:
  - `TMDBService`, `DiscoverService`, `ListService`, `ProfileService`, `ReviewService`, `WatchProgressService`,
    `ShareLinkService`, `MessagingService`, `AIService`
- Services should accept a lightweight HTTP client and/or Supabase client wrapper.

## State model suggestion
Use a shared enum:
```swift
enum Loadable<T> {
  case idle
  case loading
  case loaded(T)
  case empty
  case failed(String)
}
