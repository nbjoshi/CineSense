# Lists (Spotify-like) — Claude Implementation Instructions (Schema-Aligned)

## Goal
Make **Lists** the core “library” experience (Spotify-style playlists), backed by the Supabase schema:

- `lists` = playlists (custom + system)
- `list_items` = items saved inside a playlist (movie/tv + TMDB id)
- `list_members` = sharing/collaboration access control

**Important:** TMDB metadata is not stored in Supabase. The DB stores only identifiers + user content.

---

## Data Model Mapping (Must Follow)

### Playlist (DB: `lists`)
A playlist is a row in `public.lists`:
- `id` (uuid)
- `owner_id` (uuid, required)
- `name`
- `description` (optional)
- `is_public`
- `is_collaborative`
- `system_key` (optional): `watchlist | favorites | watched`

### Playlist item (DB: `list_items`)
An item in a playlist is identified by:
- `list_id` (uuid → lists.id)
- `media_type` (`movie | tv`)
- `tmdb_id` (bigint)

Optional item fields:
- `note` (optional)
- `sort_order` (optional)
- `added_by` (optional)

**Uniqueness:** `(list_id, media_type, tmdb_id)` is unique.  
So “already in playlist” is determined by an existing row in `list_items`.

### Playlist members (DB: `list_members`)
Used only for collaborative behavior:
- composite PK (`list_id`, `user_id`)
- `role` default `viewer`
- `added_by` optional

---

## Feature: “+ Playlist” from MediaDetail (Spotify-like Add Dialog)

### Entry point
On the **MediaDetail card**, user taps **“+ Playlist”** to open an add-to-playlists dialog.

### Dialog layout (required)
1) **Header**
   - Title: `Add to Playlist`
   - Close (X)

2) **Create new playlist row (top)**
   - Text field: playlist name
   - Optional: toggles:
     - Public (`is_public`)
     - Collaborative (`is_collaborative`) (optional for MVP)
   - Button: `Create`
   - On create:
     - Insert into `lists` using `owner_id = auth.uid()`
     - Immediately reflect in the list UI (optimistic insert or refetch)
     - If created successfully, allow selecting it for the current media

3) **Playlists list (below create)**
   - Show existing playlists the user can add to:
     - System lists (`system_key` not null) at top
     - Custom lists below
   - Each row includes:
     - Playlist name
     - Optional icon/label for system lists (Watchlist/Favorites/Watched)
     - Optional collaborative indicator if `is_collaborative = true`
     - Right-side toggle/button to include/exclude the media in that playlist

4) **Sticky bottom action**
   - Sticky/hovering button: `Done` (or `Add` → `Done` after changes)
   - Pressing it closes the dialog.
   - If you implement immediate toggles (recommended), the button is mainly “close”.
   - If you implement staging, the button commits changes (see behavior section).

---

## Selection Behavior (Schema-Accurate)

### Determining initial state
When opening dialog, load:
- All playlists to display (system + custom)
- All `list_items` for the current media across playlists OR query per playlist

For each playlist row:
- If a row exists in `list_items` with:
  - `list_id = playlist.id`
  - `media_type = currentMediaType`
  - `tmdb_id = currentTmdbId`
  → then it is **selected**.

### Toggling ON (Add to playlist)
On selecting a playlist:
- Insert row into `list_items`:
  - `list_id = playlist.id`
  - `media_type = movie|tv`
  - `tmdb_id = currentTmdbId`
  - optional: `sort_order` (if you use it), `note` null

If the unique constraint triggers a duplicate error:
- Treat as success (item already exists); keep UI selected.

### Toggling OFF (Remove from playlist)
On deselecting a playlist:
- Delete from `list_items` by composite key:
  - `.eq("list_id", playlist.id)`
  - `.eq("media_type", mediaType)`
  - `.eq("tmdb_id", tmdbId)`

**Do NOT delete by UUID `id`** (there is no `id` column for `list_items`).

### Button styles
- If selected (item exists in playlist):
  - show a **filled** button with the app theme color
- If not selected:
  - show an outline/neutral style

---

## Lists Tab Requirements

### Lists tab layout
- **System lists** at the top:
  - watchlist
  - favorites
  - watched
- **Custom lists** below
- Show a collaborative indicator if `is_collaborative = true`

### List detail view
When a playlist is opened:
- Fetch its items from `list_items` by `list_id`
- Order items using:
  - `sort_order` ascending, then `created_at` ascending (recommended)
- For each item:
  - Resolve TMDB metadata client-side using `media_type + tmdb_id`
  - Display poster/title/year as normal
- Optional:
  - support item notes (`note`)
  - support reordering via `sort_order`

### Collaborative member management (optional MVP)
If `is_collaborative = true`:
- Provide a member management section:
  - list existing members from `list_members`
  - show roles (`viewer`, etc.)
  - invite flow inserts into `list_members` (future wiring ok)

---

## API/Service Expectations (Swift)

### Required service calls
- Create playlist: insert into `lists`
- Read playlists: select from `lists`
- Read playlist items: select from `list_items` by `list_id`
- Add item: insert into `list_items`
- Remove item: delete from `list_items` by `(list_id, media_type, tmdb_id)`
- Delete playlist: delete from `lists` (cascade cleans up items/members)

### Must-have Swift enums (raw string)
- `MediaType: String, Codable { case movie, tv }`
- `SystemKey: String, Codable { case watchlist, favorites, watched }` (optional but recommended)

---

## Acceptance Criteria
- User can open “+ Playlist” from MediaDetail
- User can create a new playlist from the dialog
- User sees system lists + custom lists
- User can add/remove the current media to/from any playlist (stored in `list_items`)
- Selected state reflects DB existence (no duplicates due to unique constraint)
- Lists tab shows system lists first, then custom lists
- Playlist detail shows items resolved via TMDB using `media_type + tmdb_id`
- Deleting a playlist removes related items/members (cascade behavior)
