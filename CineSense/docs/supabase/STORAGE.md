# Supabase Storage

## Buckets
- `ai_uploads` (private): temporary screenshot uploads for AI identification
- `avatars` (public or private w/ signed URLs): profile pictures

## ai_uploads rules
- Upload path must be user-scoped: `<userId>/<uuid>.<ext>`
- Only images allowed: jpeg/png/webp
- Signed upload URL expires quickly (60s currently)

## avatars rules
- Store `avatar_url` in `profiles.avatar_url`
- Prefer:
  - upload -> get public URL OR signed URL strategy
  - keep a consistent path per user (e.g. `<userId>/avatar.jpg`) to replace easily
