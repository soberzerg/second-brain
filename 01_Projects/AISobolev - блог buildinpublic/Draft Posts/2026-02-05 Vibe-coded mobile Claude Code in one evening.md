# I vibe-coded mobile Claude Code in one evening and open-sourced it

No access to Claude Code from my phone. And it was driving me crazy.

On the go, idea hits — nowhere to capture it. Client pings — need to create a task in the tracker. Want a note in Obsidian — wait till you're at your laptop.

Meanwhile Claude Code sits on my VPS, MCP servers connected, knowledge base ready. Everything's there — just no mobile entry point.

The fix was almost embarrassingly simple: a Telegram bot that bridges messages to Claude Code CLI.

Not a regular chatbot hitting the API. A full bridge to Claude Code with all its superpowers:

→ MCP servers (YouGile, Firecrawl, n8n, Gemini Vision)
→ File system (Obsidian vault)
→ CLAUDE.md with full project context
→ Sessions with conversation memory

"Create task X" — task lands in the tracker. "Save idea Y" — note in Obsidian. "What do you think about Z?" — full conversation with an AI that knows all my projects.

Under the hood: Python bot + Claude Code CLI in --print mode. Session manager keeps dialogue context. Git sync for notes. Auth via Telegram ID whitelist.

Vibe-coded it in one evening. Phase 1 — working text bridge. Photos, files, auth — all functional.

Open-sourced it because the problem is universal. Tons of people use Claude Code, and everyone wants mobile access. Fork it, plug in your MCP servers, make it yours.

Not a SaaS. Not a product. A tool for those already in the Claude Code ecosystem who want it in their pocket.

GitHub link in the comments.

Next up: voice messages, smart forwarded content routing, morning digests.

If you use Claude Code — would you want mobile access via Telegram?
