# TG Claude Code Assistant - Masterplan

## Application Overview

A Telegram bot that serves as a mobile interface to Claude Code running on a VPS. Not a regular API chatbot — but full access to an AI agent with all its tools, skills, and knowledge base. Manage tasks, notes, projects, and chat with Claude directly from Telegram — on the go, no SSH or computer required.

**Who it's for:** Sergei + assistant (2 users)
**Problem:** No mobile access to Claude Code and no single entry point for tasks/notes/planning

## Goals and Objectives

- Mobile access to Claude Code with all MCP servers and skills
- Single entry point: tasks (YouGile), notes (Obsidian), AI chat — all from Telegram
- Forwarded content processing: links, messages, files, voice notes
- Proactive notifications: reminders, deadlines, digests

## Target Audience

**Primary segment:** Solo founder/developer juggling multiple projects who needs a mobile AI assistant

**User Persona:**
- Sergei, 30+, runs 3-5 projects in parallel
- Uses Obsidian as a knowledge base, YouGile as a task tracker
- On the go, wants to quickly add a task, jot down an idea, ask AI
- Receives chats/links that need to be processed and saved
- Doesn't want to waste time on SSH or wait for computer access

## Core Features

### MVP (Phase 1)

1. **Telegram <-> Claude Code Bridge** — Bot receives text messages from Telegram, passes them to Claude Code CLI on VPS, returns the response. Sessions with timeout (preserving dialog context).

2. **Obsidian Integration (second-brain)** — Via Claude Code on VPS: create notes, add to inbox, read notes, search the vault. Synced via git pull/push.

3. **YouGile Integration** — Create tasks, view boards, update statuses — via the YouGile MCP server connected to Claude Code.

4. **AI Chat** — Questions, brainstorming, analysis — full-featured conversation with Claude that knows the context of all projects (CLAUDE.md).

5. **Telegram ID Authorization** — Whitelist of 2 user IDs (Sergei + assistant). Everyone else gets "access denied".

6. **Photo and File Processing** — Receive photos/documents via Telegram, save to VPS, analyze with Claude (Gemini Vision MCP for images).

### Phase 2 (Post-Validation)

1. **Voice Messages** — Speech recognition via Whisper API or equivalent, pass text to Claude Code. "Dictate a task/note" mode.

2. **Forwarded Content with Smart Processing** — Forward a message/link -> bot automatically determines: save as note, create task, extract contacts, add to inbox.

3. **Proactive Notifications** — Morning digest (today's tasks), deadline reminders, weekly summary. Via cron on VPS -> Telegram API.

4. **Shortcut Commands** — `/tasks` — my tasks for today, `/inbox` — what's in inbox, `/daily` — run daily review, `/week` — weekly summary.

### Future Development

- Multi-user mode with role-based access
- Calendar integration (Google Calendar)
- Real-time voice input/output
- Web interface as Telegram alternative
- Productization: offer as a service to AGIency clients

## Tech Stack (Recommendations)

| Component | Recommendation | Alternatives | Rationale |
|-----------|---------------|--------------|-----------|
| Bot Server | Python (python-telegram-bot) | Node.js (telegraf), Go | Python — fast to start, great TG + subprocess libraries |
| AI Engine | Claude Code CLI (--print mode) | Claude API directly | Full access to MCP servers, skills, file system |
| Notes Storage | Git repo (second-brain) | — | Already exists, synced via git |
| Task Tracker | YouGile API (via MCP) | — | Already in use |
| Voice | Whisper API (OpenAI) | Deepgram, Google STT | Best Russian language quality |
| Task Queue | Redis / file-based queue | RabbitMQ, NATS | For session management and message queuing |
| VPS | Current VPS with n8n | — | Infrastructure already in place |
| Deployment | systemd service | Docker, PM2 | Simplicity for a single instance |

## Architecture

```
Telegram
   |
   v
[Python TG Bot] ---- user_id authorization
   |
   v
[Session Manager] ---- session timeout, message queue
   |
   v
[Claude Code CLI] ---- --resume for sessions, --print for responses
   |
   ├── MCP: YouGile
   ├── MCP: Firecrawl
   ├── MCP: Context7
   ├── MCP: Gemini Vision
   ├── MCP: n8n
   ├── File System (second-brain repo)
   └── CLAUDE.md (user context)
```

### Key Architectural Decisions

1. **Claude Code CLI over API** — provides access to all MCP servers, skills, and file system. This is what makes the bot more powerful than a regular chatbot.

2. **--print mode** — Claude Code supports `claude --print` for non-interactive use and `--resume` for session continuation. This is the foundation of the interaction layer.

3. **Session Manager** — stores mapping: telegram_user_id -> claude_session_id. Session timeout: 15-30 minutes of inactivity. After timeout — new session, but CLAUDE.md ensures context continuity.

4. **Git sync** — before each session: `git pull`, after changes: `git add + commit + push`. Fully automated.

## Conceptual Data Model

### Core Entities

- **User** — telegram_id, name, role (owner/assistant), last_active
- **Session** — session_id (Claude Code), telegram_user_id, created_at, last_active, status (active/expired)
- **Message Log** — telegram_message_id, session_id, direction (in/out), content, timestamp, type (text/voice/photo/file)
- **Notification** — type, schedule (cron), template, telegram_user_id, active

### Storage

Minimal database — SQLite on VPS for sessions and logs. Primary data lives in Obsidian (files) and YouGile (tasks).

## UI/UX Principles

- **Telegram-native** — no custom UI, just text + inline buttons when needed
- **Fast input** — type text -> get result. Minimum steps
- **Smart routing** — bot determines what to do: "add task X" -> YouGile, "note idea Y" -> Obsidian inbox, "what do you think about Z?" -> chat
- **Markdown responses** — Claude Code responds in markdown, Telegram supports basic markdown
- **Long responses** — if response > 4096 characters (TG limit), split into parts
- **References:** Notion AI in Telegram, ChatGPT bot, Molyanov's bot

## Authentication and Security

- **Authentication method:** Telegram user ID whitelist in config. Two IDs: Sergei + assistant.
- **Access:** Equal for both users. Separate sessions — each in their own chat.
- **Data protection:** VPS with SSH keys, private git repo, Claude Code Max Plan (data not used for training).
- **Rate limiting:** Basic — no more than N messages per minute per user to avoid spamming Claude Code.

## Development Phases

### Phase 1: MVP — Text Bridge

- [ ] Install Claude Code CLI on VPS
- [ ] Configure CLAUDE.md and MCP servers on VPS (mirror of local configuration)
- [ ] Clone second-brain repo to VPS
- [ ] Write Python Telegram bot with user_id authorization
- [ ] Implement `claude --print` invocation from bot
- [ ] Add Session Manager (timeout, --resume)
- [ ] Set up git sync (auto pull/push)
- [ ] Deploy as systemd service
- [ ] Testing: text chat, YouGile tasks, Obsidian notes

### Phase 2: Media and Voice

- [ ] Photo processing via Telegram API -> save to VPS -> pass to Claude
- [ ] File/document processing
- [ ] Whisper API integration for voice messages
- [ ] Smart routing for forwarded messages

### Phase 3: Proactivity

- [ ] Cron jobs for notifications (morning digest, deadlines)
- [ ] Shortcut commands (/tasks, /inbox, /daily, /week)
- [ ] Weekly summary

## Potential Challenges and Solutions

| Challenge | Impact | Proposed Solution |
|-----------|--------|-------------------|
| Claude Code CLI slow response (10-30s) | User waits, UX suffers | Send "typing..." indicator, stream partial responses if possible |
| Claude Code Max Plan limits | Active use by two people may hit limits | Monitor usage, notify when approaching limits |
| Git conflicts during sync | Data may be lost | Auto-merge strategy, separate branch for VPS, periodic merge |
| Long Claude responses (>4096 chars) | Telegram truncates | Split into parts, send sequentially |
| Concurrent messages from 2 users | Claude Code CLI — single process | Message queue, sequential processing (or 2 CC instances) |
| Security: VPS with full access | VPS breach = data exposure | SSH keys, firewall, minimal open ports, regular updates |
| Russian voice recognition | Recognition quality | Whisper large-v3 — best for Russian |

## Future Opportunities

- Productization for AGIency clients (each client — own bot + own Claude Code)
- Web interface as Telegram alternative
- Google Calendar integration for scheduling
- Text-to-speech for voice responses
- Automatic daily review generation based on day's activity
- Email integration (forward emails to bot)

---
*Created with /prd*
