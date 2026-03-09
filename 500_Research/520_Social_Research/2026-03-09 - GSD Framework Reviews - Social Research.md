---
type: social-research
date: 2026-03-09
status: active
tags: [gsd-framework, claude-code, ai-coding, framework-comparison, bmad, sparc, superpowers]
---

# GSD Framework — Отзывы и критика (Social Research)

> AI-синтезированный анализ на основе данных из X/Twitter, Reddit и Medium.
> Период: январь — март 2026.

## Что такое GSD

**GSD (Get Shit Done)** — open-source фреймворк для agentic coding с Claude Code (github: gsd-build/get-shit-done, 25.4K+ stars). Решает проблему "context rot" — деградации качества при заполнении context window. Использует phases, sub-agents, spec-driven development.

Автор: @gsd_foundation (Twitter), Taimur Ibrahim (LinkedIn).

## Ключевые находки

### 1. Главная критика: token consumption и babysitting

**@Divkix** (Divanshu Chauhan):
> "What do you guys use for spec-based development? I tried gsd, openspec, spec-kit. **gsd uses too much tokens and is slow, can only work on one feature at a time.** openspec is too lightweight, spec-kit is good... i use superpowers too"
> — [Источник](https://x.com/Divkix/status/2030483012996239794)

**@junelovestmh** (Junior Love):
> "I like GSD as a concept, but **once I am in like phase 2, I immediately feel like I'm baby sitting.** I know Claude does it best, but I am on many different agent clis... Curious to watch the video"
> — [Источник](https://x.com/junelovestmh/status/2030653528377561555)

### 2. Упускает мелочи в implementation (подтверждение твоего опыта)

По данным Reddit (r/ClaudeCode — "I finally decided to use gsd for claude code"):
- GSD **тратит основной объём токенов на фазу discuss и plan**, а на implementation остаётся меньше контекста
- Не приходит к конечному результату: **linter errors, test failures, incomplete configs** остаются
- Фреймворк ориентирован на high-level planning, а не на "доведение до зелёных тестов"

По данным Reddit (r/ClaudeCode — "Best framework for code evolutions: GSD, Superpowers, nothing?"):
- Консенсус: **лучше строить свой workflow**, заточенный под конкретный проект
- GSD хорош как стартовая точка, но нуждается в кастомизации

### 3. Сравнение с другими фреймворками

| Фреймворк | Сильные стороны | Слабые стороны |
|-----------|----------------|----------------|
| **GSD** | Структура phases, борьба с context rot, sub-agents | Token-heavy, slow, babysitting после phase 2, упускает детали реализации |
| **BMAD** | Agentic workflows, end-to-end подход | Агенты перестали работать в новых версиях Claude Code (r/ClaudeCode) |
| **SPARC** | Структурированное планирование, risk analysis | Тяжеловесный, "enterprise roleplay" |
| **Superpowers** | Skill cascade pattern, лёгкий | Менее структурирован |
| **Spec-Kit** | Хороший баланс | Менее известен |

**@shahwan42** (Ahmed Shahwan, Sr. Software Engineer):
> "Well, Claude Max is... different! I'm trying to build the same app in different ai frameworks with less worrying about quota. **BMAD, Spec-Kit, GSD, Bare Claude.** Interesting findings."
> — [Источник](https://x.com/shahwan42/status/2030603310051332464)

**@mayorxbt** — top 10 claude code plugins:
> "1. superpowers... 2. GSD (get shit done) → runs full development cycles using sub-agents..."
> — [Источник](https://x.com/mayorxbt/status/2029455642662998124)

### 4. Положительные отзывы

**Joel Rothman** (Medium, комментарий к статье Joe Njenga):
> "Thanks Joe — I've been using this for about 2 weeks on an intermediate size brownfields saas project and **it is the best yet (after trying auto-claude, spec kit and bmad).**"

**Mark Lummus** (Medium):
> "I started using this afternoon, and this works well (so far). It brings together so many best practices. And **the repeatability appears to be spot-on.**"

**@BrOrlandi** (Bruno Orlandi, CTO):
> "Testei o Get Shit Done (GSD) no Claude Code para criar um aplicativo Android. Por enquanto gostei muito da experiencia — **ele trabalhou por 1 hora de madrugada** em um projeto que vou testar agora."
> — [Источник](https://x.com/BrOrlandi/status/2030679020031910199)

### 5. Тренд: гибриды и кастомные решения

**@SamMillunchick:**
> "inspired by **superpowers, the impeccable skill cascade pattern, and gsd 2.0's ideas** on multi-session AI coding"
> — [Источник](https://x.com/SamMillunchick/status/2030547407742570946)

Reddit (r/ClaudeCode — "Best framework for code evolutions"):
> "What I recommend doing is really just **building your own**, working with Claude Code to help you build it based on your voice and what you're building."

Reddit (r/LLMDevs — "SuperClaude vs BMAD vs Claude Flow vs Awesome Claude"):
- Активное обсуждение всех фреймворков
- Нет явного "победителя" — каждый подходит для своего случая

## Проблемы GSD, которые ты выявил (подтверждение)

Твой опыт полностью совпадает с community feedback:

1. **Хорошо планирует, плохо завершает** — основная токен-нагрузка на discuss/plan фазы
2. **Упускает мелочи**: linter errors, test failures, Makefile не готов
3. **Нет интеграционного тестирования**: frontend + backend связка не проверяется
4. **Babysitting**: после начальных фаз нужно ручное вмешательство
5. **One feature at a time**: не параллелизирует работу

## Возможные решения (из community)

1. **Гибридный подход**: Взять GSD для planning phase + свой verification loop для implementation
2. **Добавить verification gate**: автоматическая проверка linter + tests + build после каждой фазы
3. **Кастомный CLAUDE.md**: прописать обязательные шаги (lint, test, Makefile) в post-implementation checks
4. **Superpowers skill cascade** для execution phase вместо GSD sub-agents
5. **Horst Herb** (Medium): "break the complex task into steps, wrote a bird's eye view brief document explaining the whole, and separate documents for each step. Instructions include to **keep modifying until all tests passed**"

## Источники

### X/Twitter
- https://x.com/Divkix/status/2030483012996239794 — критика token usage
- https://x.com/junelovestmh/status/2030653528377561555 — babysitting
- https://x.com/shahwan42/status/2030603310051332464 — сравнение фреймворков
- https://x.com/BrOrlandi/status/2030679020031910199 — положительный опыт
- https://x.com/mayorxbt/status/2029455642662998124 — top 10 plugins
- https://x.com/SamMillunchick/status/2030547407742570946 — гибридные решения
- https://x.com/gsd_foundation/status/2030361888681239003 — официальный аккаунт

### Reddit
- r/ClaudeCode: "I finally decided to use gsd for claude code"
- r/ClaudeCode: "Best framework for code evolutions: GSD, Superpowers, nothing?"
- r/ClaudeCode: "GSD (Get Shit Done) usage"
- r/ClaudeCode: "gsd framework+skills"
- r/ClaudeAI: "Get Shit Done: The #1 CC Framework"
- r/ClaudeAI: "I've Massively Improved GSD"
- r/LLMDevs: "SuperClaude vs BMAD vs Claude Flow vs Awesome Claude"

### Medium / LinkedIn
- Joe Njenga: "I Tested GSD Claude Code: Meta-Prompting System That Ships Faster"
- Laxmikant Pandit (LinkedIn): "Preventing AI Context Rot with GSD Framework"
- Taimur Ibrahim (LinkedIn): GSD GitHub repo announcement

---

## Связанные документы

- [[PRD-2-AI-ROP]] — проект, где тестировался GSD
