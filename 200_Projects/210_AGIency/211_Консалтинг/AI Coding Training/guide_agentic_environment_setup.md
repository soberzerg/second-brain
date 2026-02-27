# Guide: Setting up an Agentic Engineering Environment (2026 Edition)

**From Vibe Coding to Systems Engineering.**

This guide is your toolkit for shifting from manually typing syntax to managing AI agents. As promised in the carousel.

## 1. The Stack (Инструментарий)

Forget VS Code with Copilot. You need an Agentic IDE.

### IDEs (Выбор оружия)

1.  **Cursor** (The Standard).
    *   **Pro:** Best UX, native "Agent" mode (Composer), huge community.
    *   **Setup:** Download -> Import VS Code settings -> Enable "Composer" & "Yolo Mode".
    *   **Tip:** `Cmd+I` is your new `Cmd+C`.

2.  **Windsurf** (The Contender).
    *   **Pro:** By Codeium. "Flow" mode interacts deeply with terminal and codebase.
    *   **Setup:** Good alternative if Cursor feels heavy or expensive.

3.  **Cline (VS Code Extension)** (The Open Source Hero).
    *   **Pro:** Runs local models, DeepSeek R1, customizable. Total privacy.
    *   **Setup:** Install in VS Code -> Connect OpenRouter API.

### Models (Мозги)

*   **Claude 3.5 Sonnet:** The current King of Coding. High reasoning, large context. Use for *writing* code.
*   **DeepSeek R1:** The best open/cheap reasoning model. Great for the *Plan* phase.
*   **Gemini 1.5 Pro:** Huge context window (2M tokens). Use for "Read the whole repo" tasks.

---

## 2. Configuration (Настройка)

Agent needs rules. Without rules, it's just a chatbot.

### .cursorrules
Place this file in your project root. Copy-paste this template:

```markdown
# Role
You are a Senior Agentic Engineer. You do not just write code; you design systems.

# Behavior
- **Spec First:** Never write code without a plan in `docs/specs/`.
- **No Yapping:** Be concise. Don't explain "Here is the code". Just do it.
- **Testing:** Every PR must have tests. No exceptions.
- **Security:** Check for vulnerabilities before suggesting code.

# Tech Stack
- Frontend: [Your Stack]
- Backend: [Your Stack]
```

### MCP (Model Context Protocol)
Connect your agent to the outside world.
*   Install servers for: PostgreSQL (database access), GitHub (PR management), Filesystem (editing).
*   *Cursor Settings -> MCP -> Add new.*

---

## 3. The New Workflow (Пайплайн)

Stop typing `def main():`. Start typing `create spec`.

**Phase 1: Spec (Спецификация)**
*   Don't code. Chat.
*   **Prompt:** "I want to build [Feature X]. Ask me 5 clarifying questions to nail the requirements."
*   **Result:** `docs/specs/feature_x_spec.md`.

**Phase 2: Plan (План)**
*   **Prompt:** "Read `feature_x_spec.md`. Create a step-by-step implementation plan. Break it down into atomic tasks."
*   **Result:** `docs/plans/feature_x_plan.md` or updated `task.md`.

**Phase 3: Agent Loop (Исполнение)**
*   **Cursor Composer:** "Execute Step 1 from the plan. Run tests. Verify."
*   *You are now the reviewer.*
*   If it fails/hallucinates: "Restore context. Read the error. Fix it."

**Phase 4: Review (Ревью)**
*   Don't trust. Verify.
*   Read the diffs.
*   Run the app.
*   **Commit.**

---

## 4. Checklist: Are you ready?

- [ ] Agentic IDE installed (Cursor/Windsurf).
- [ ] LLM API Keys set up (Anthropic/OpenRouter).
- [ ] `.cursorrules` created in project root.
- [ ] `docs/specs` folder created.
- [ ] Mental shift: You are the Manager.

---
*Welcome to 2026. Happy Agenting.*
