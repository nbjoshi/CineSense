# CineSense Setup

## Initial Setup

### 1. Configure API Keys

Copy the template file to create your local Info.plist:

```bash
cp CineSense/Info.plist.template CineSense/Info.plist
```

Then edit `CineSense/Info.plist` and replace the placeholder values:

- `SUPABASE_URL`: Your Supabase project URL (from Supabase Dashboard → Settings → API)
- `SUPABASE_ANON_KEY`: Your Supabase anon/public key (from Supabase Dashboard → Settings → API)
- `TMDB_API_KEY`: Your TMDB API key (from https://www.themoviedb.org/settings/api)
- `TMDB_READ_ACCESS_KEY`: Your TMDB Read Access Token (from TMDB API settings)

### 2. Supabase Configuration

In your Supabase Dashboard:

1. **Enable Email Auth**
   - Go to Authentication → Providers
   - Enable "Email" provider

2. **Add Redirect URL**
   - Go to Authentication → URL Configuration
   - Add to Redirect URLs: `cinesense://auth-callback`

3. **Verify Database Trigger** (for auto-creating user profiles)
   - The `handle_new_user()` trigger should be set up
   - See database migrations in `supabase/migrations/`

### 3. Build and Run

Open `CineSense.xcodeproj` in Xcode and run on simulator or device.

## Security Notes

- **Never commit Info.plist** - it contains API keys
- Info.plist is in .gitignore
- Use Info.plist.template as reference for required keys
