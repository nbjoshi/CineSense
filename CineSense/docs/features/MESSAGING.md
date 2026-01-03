# Messaging (under Profile tab)

## Goal
Friends + activity + realtime messaging.

## Requirements
### Friends
- “Add friend” control at top
- Friends list below
- Friend profile view shows:
  - display name, avatar, bio
  - recent activity
  - shared lists (optional)

### Activity feed
- Show friends’ activity (list additions, reviews, watched)
- Implement using Supabase Realtime where appropriate

### Messages
- Direct messages
- Group chats
- Realtime updates
- Image uploads for messages

## Data model
Not fully defined in schema yet. When implementing, create:
- conversations
- conversation_members
- messages (text + optional image)
- message_attachments (optional)

## Acceptance Criteria
- Realtime message updates
- Basic moderation hooks:
  - blocks
  - reports
