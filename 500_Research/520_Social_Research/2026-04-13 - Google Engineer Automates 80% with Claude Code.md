---
type: social-research
date: 2026-04-13
source: https://x.com/noisyb0y1/status/2043609541477044439
author: Noisy (@noisyb0y1)
tags: [claude-code, ai-automation, developer-productivity, google, passive-income]
status: active
---

# Google Engineer Automates 80% of Work with Claude Code

**Автор:** Noisy (@noisyb0y1) — Crypto DEV, 12.3K followers
**Дата:** 2026-04-13
**Просмотры:** ~3M | **Лайки:** 1,560 | **Букмарки:** 8,289 | **Репосты:** 157

## Суть поста

Google-инженер с 11 годами опыта автоматизировал 80% рабочего дня с помощью Claude Code и простого .NET-приложения. Теперь работает 2-3 часа в день, зарабатывая $28K пассивного дохода.

## Ключевые инструменты

### 1. CLAUDE.md

- GitHub-файл, набравший 15,000 звёзд за неделю
- Основан на правилах Andrej Karpathy для предотвращения типичных ошибок LLM при кодинге
- Четыре принципа: простота, без фреймворков, минимальные зависимости, чистый код
- Применяется ко всему проекту автоматически

### 2. Everything Claude Code

- Репозиторий: github.com/affaan-m/everything-claude-code
- 153,000+ звёзд
- 27 агентов и 64 навыка: планирование, ревью, безопасность и др.
- Работает с несколькими инструментами; можно устанавливать выборочно

### 3. Claude Code v2.1.100 — проблема с токенами

- Анализ показал 20,000+ лишних токенов на стороне сервера
- Рекомендация: зафиксировать версию v2.1.98

## Кейс-стади: система из 3 частей

1. **CLAUDE.md** — правила и ограничения для AI
2. **Агенты** — автоматизация рутинных задач
3. **15-минутный GitLab цикл** — непрерывная интеграция

Экономия: $3K–$12K/месяц

## Интересные комментарии

- **Stacy Real:** "90% Google-инженеров, которых я знаю, уже работают 2-3 часа без всего этого" — скептицизм
- **Chen Avnery:** Хвалит CLAUDE.md за реальное снижение нарушений с 40% до 3% — "институциональная память"
- **Armaan Sidhu:** Подробный анализ — подчёркивает разрыв в инфраструктуре AI-использования, валидирует критику (обслуживание, токены), отмечает переход от AI-как-чатбота к AI-как-инфраструктуре

## Выводы

- Пост отражает массовый интерес к AI-driven developer productivity
- Позиционирует AI как "операционную систему" для кодинга
- Вирусный в AI/dev/crypto кругах (~3M просмотров за 2 дня)
- Ключевая идея: "три команды и один файл" вместо ручного кодинга

## Оригинал статьи

> Источник: [BlockBeats (EN перевод)](https://m.theblockbeats.info/en/news/61983)
> Original Author: @noisyb0y1

A Google engineer with 11 years of experience automated 80% of his work using Claude Code and a simple .NET application.

Today, he only needs to work 2–3 hours a day instead of the original 8 hours, spending the rest of his time mostly in a "relaxed" state, with the system running on its own, bringing him a passive income of $28,000 per month.

What he has mastered is the set of methods that you have yet to understand.

### Part 1 — Write CLAUDE.md Following the Karpathy Principle

Andrej Karpathy — one of the world's most influential AI researchers — has systematically summarized the most common errors of large language models when writing code: overdesign, ignoring existing patterns, and introducing unnecessary additional dependencies.

Someone consolidated these observations into a unified CLAUDE.md file. As a result, the project received 15,000 stars on GitHub within a week, implying that 15,000 individuals, in a way, altered their workflow because of this.

The core idea is actually quite simple: if errors are predictable, they can be preemptively avoided through explicit instructions. Just placing a markdown file in the code repository provides a structured set of behavioral rules for Claude Code, thereby standardizing decision-making and execution throughout the project.

Within this file, there are primarily four core principles:

- Think First, Code Later → Avoid mistaken assumptions and overlooked trade-offs
- Embrace Simplicity → Prevent over-engineering and bloated abstractions
- Surgical Modifications → Refrain from changing code that no one requested to change
- Goal-Driven Execution → Test first, then validate against clear success criteria

It doesn't rely on any framework, nor does it require complex tools — just one file can alter Claude's behavior at the project level.

**The real difference lies in:**

- Without using CLAUDE.md: Claude violated the standards in about 40% of cases
- With Karpathy's CLAUDE.md: Violation rate reduced to about 3%
- Setup time: Only 5 minutes

**Command to auto-generate your own CLAUDE.md file:**

```
claude -p "Read the entire project and create a CLAUDE.md based on:
Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution.
Adapt to the real architecture you see." --allowedTools Bash,Write,Read
```

### Part 2 — Everything Claude Code: A Full Engineering Team in a Repository

Everything Claude Code (with over 153k stars on GitHub)

This is not just a set of prompts but more like a complete AI operating system for building products.

- 30+ specialized agents: planner.md → Feature Planning, architect.md → System Design Decision, tdd-guide.md → Test-Driven Development, code-reviewer.md → Code Quality and Security Review, security-reviewer.md → Vulnerability Analysis, loop-operator.md → Automated Loop Execution
- 180+ skills: TDD, Security, Research, Content Generation — all preconfigured
- Built-in AgentShield: Configuration directly integrates 1282 security tests

Works across different tools like Claude, Codex, Cursor, OpenCode, Gemini — a unified system, everywhere.

Installation:

```
/plugin marketplace add affaan-m/everything-claude-code
```

Alternatively, manual installation — just copy the components you need to the `.claude/` directory of your project. Do not load everything at once — loading 27 agents and 64 skills simultaneously will likely deplete your contextual quota before you even input your first prompt. Only keep the parts you truly need.

**The real difference is:**

- Before: You're conversing with AI
- After: You're managing an autonomously running AI engineering team

### Part 3 — A Hidden "Scandal": Claude Code v2.1.100 Secretly Eating Your Tokens

Someone intercepted and analyzed full API requests of 4 different versions of Claude Code by setting up an HTTP proxy.

They discovered:

- v2.1.98: 169,514 bytes request → 49,726 tokens charged
- v2.1.100: 168,536 bytes request → 69,922 tokens charged
- difference: -978 bytes but +20,196 tokens

Although v2.1.100 sent fewer data bytes, it charged an extra 20,000 tokens. This "inflation" occurred entirely on the server side — you cannot see it or verify it through the /context interface.

Why this is more than just a billing issue: the additional 20,000 tokens will be stuffed into Claude's actual context window. This means:

- Your CLAUDE.md directives will be diluted by this additional 20,000 "hidden content"
- In lengthy conversations, the output quality will deteriorate faster
- When Claude disregards your rules, it's hard to pinpoint the reason
- Claude Max's usage quota will be consumed about 40% faster than normal

**Fix in just 30 seconds:** `npx claude-code@2.1.98`

### Case Study: What a Full Automation System Looks Like

An engineer with 11 years of experience built a system consisting of three parts:

**Result after one week:**

- Before: Coding 8 hours a day
- After: Only needing 2–3 hours a day for code review and testing
- Code quality: Virtually unchanged — because he reviews each one
- Team status: Always online — mouse moves automatically every minute
- Remaining time: Free all day

It's not some "magic," but the result of CLAUDE.md + appropriate agents + a 15-minute loop cycle.

**What You Gain After Reading:**

- Before: Claude would deviate from existing norms 40% of the time → After: With Karpathy's CLAUDE.md, the violation rate drops to 3%
- Before: It would take you weeks to set up agents → After: 27 agents are ready to use out of the box
- Before: Claude Max would deplete the quota in 2–3 hours → After: Reverting to v2.1.98 can restore about 40% of the usage cap
- Before: Needing 8 hours a day for coding → After: Only needing 2–3 hours for review, with the rest being automated by the system
- Setup Time: 15–20 Minutes
- Daily Savings: 5–6 Hours
- Monthly Savings: 100–120 Hours

If your time is valued at $30 per hour — you're actually "losing invisibly" $3,000–$3,600 per month. If it's $100 per hour — that's $10,000–$12,000 flowing away each month, just because you're still manually writing code that Claude could have done on his own.

Most developers never reach this level — not because they can't, but because they think it's complicated. In reality, between you and "full automation," there are just three commands and one file.

The engineer I mentioned at the beginning is not a genius or a senior Google engineer. He just spent one evening setting up the system — since then, the system does the work, and he just enjoys life.

You can do the same thing tonight. While others are still debating whether AI will replace developers, those who have set up the system are just making money and relaxing.

---

## Связанные документы

- [[CLAUDE]] — наш собственный CLAUDE.md в проекте second-brain
