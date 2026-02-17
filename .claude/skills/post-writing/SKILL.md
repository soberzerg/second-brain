---
name: post-writing
description: Writes engaging posts using top copywriting techniques (hooks, storytelling, slippery slide). Use when the user asks to write a post, draft content for social media (Telegram, Threads, X, LinkedIn, Blog), or "rewrite this to be more engaging".
---

# Post Writing Skill

## When to use this skill

- User asks to write a post for Telegram, Threads, X, LinkedIn, or Blog.
- User wants to rewrite a text to be more engaging or "viral".
- User mentions specific copywriting techniques (hooks, slippery slide, etc.).
- User wants to write a short-form post for Threads or X.

## Workflow

1.  **Analyze & Clarify**:
    - Identify the **Goal** (sales, engagement, education, brand awareness).
    - Identify the **Target Audience** (Unaware, Problem-Aware, Solution-Aware, etc.).
    - Identify the **Key Takeaway** (What should the reader do/think after?).
    - _If any of these are missing, ASK the user first._

2.  **Select a Hook**:
    - Review `resources/hooks-guide.md` to refresh on hook types.
    - Propose **3 distinct hook options** to the user (e.g., one Story, one Problem, one Proclamation).
    - Ask the user to choose one.

3.  **Draft the Post**:
    - Once the hook is chosen, write the full draft.
    - **Tone**: Builder thinking out loud (not marketing). Use `resources/style-guide.md` for specific voice, emoji usage, and formatting nuances.
    - **Structure** (Problem → Reframe → Action):
      - **Hook** (противоречие, интрига, или личная история).
      - **Problem**: What's wrong with the current situation (personal experience, specifics).
      - **Reframe**: Why the common wisdom is incomplete (your perspective from experience).
      - **Action**: What you're doing about it + invitation to dialogue.
    - **Viral Formula** (из анализа топовых LinkedIn-постов, февраль 2026):
      - **Data**: конкретные цифры в первых строках (не "много", а "776 professionals")
      - **Narrative**: одна конкретная история или момент
      - **Framework**: модель/структура для понимания (→ стрелки, "Раньше/Сейчас", numbered)
      - Все три слоя вместе = максимальный reach. Только цифры = сухо. Только история = нет доверия. Только фреймворк = абстрактно.
    - **Formatting**:
      - Short paragraphs (1-2 lines for LinkedIn, 2-4 for Telegram).
      - → стрелки для списков (LinkedIn не рендерит markdown bullets).
      - **Bold** for key points, *italic* for accents.
      - NO парцелляция, NO em-dashes (—).
      - NO H2/H3 headers for LinkedIn (они не рендерятся).
      - **Threads:** max 500 символов, plain text (без markdown), 3-5 хештегов, одна мысль на пост.
      - **X (EN):** 280 символов/твит, English only, threads для длинного формата, hook в первом твите.
      - Accessible to non-technical audience.

4.  **Review** (Checklist from style-guide):
    - ✅ **Hook?** (противоречие, интрига, провокация)
    - ✅ **Structure?** (Problem → Reframe → Action)
    - ✅ **Accessible?** (понятно не-технарям, термины объяснены через применение)
    - ✅ **Personal?** (личный опыт, не теория)
    - ✅ **No fluff?** (каждое предложение работает, нет воды)
    - ✅ **Dialogue?** (вопрос или призыв к реакции в конце)
    - ✅ **Simple?** (без парцелляции и em-dashes, короткие абзацы)

## Instructions

### Core Principles

- **David Ogilvy**: "The headline is 80 cents of your dollar." Spend time on the hook.
- **Joseph Sugarman**: "The sole purpose of the first sentence is to get you to read the second sentence."
- **Eugene Schwartz**: "Talk to the conversation already going on in the prospect's mind." (Match the awareness level).

### Step-by-Step Execution

#### Step 1: Context Gathering

If the user provides a topic (e.g., "Write about bootstrapping"), do NOT just write. Ask:

> "To make this impactful, I need to know:
>
> 1. Who is this for? (Aspiring founders, Bootstrappers, Developers turning entrepreneur?)
> 2. What is the one thing they should remember?
> 3. Do you have a specific story, revenue number, or client win to include?"

#### Step 2: Hook Generation

Generate 3 variations following the Great Leads framework.
_Example output:_

> "Here are 3 hook options regarding [Topic]:
>
> 1. **Story Lead**: 'I had $47 in my bank account when I signed my first client.'
> 2. **Proclamation Lead**: 'You don't need a co-founder. You need discipline.'
> 3. **Promise Lead**: 'How I got my first 3 paying clients in 2 weeks with zero ad budget.'
>    Which one resonates most with the angle you want to take?"

#### Step 3: Drafting

- **Don't be boring.** Avoid "In this post I will talk about...".
- **Be specific.** Instead of "We improved performance", say "We reduced latency from 500ms to 50ms".
- **Use "You" and "I".** Make it personal.

#### Step 4: Refinement

- **Read it aloud.** If you stumble, rewrite.
- **Visuals.** Suggest where an image or screenshot would fit (e.g., `[Insert screenshot of the error log here]`).

## File Conventions

### Naming

- **Format:** `YYYY-MM-DD Название поста.md`
- **Examples:** `2026-02-11 Нашёл ассистента.md`, `2026-02-05 Vibe-coded mobile Claude Code in one evening.md`

### Paths

- **Drafts RU:** `01_Projects/AISobolev - блог buildinpublic/Draft Posts/RU/`
- **Drafts EN:** `01_Projects/AISobolev - блог buildinpublic/Draft Posts/EN/`
- **Published RU:** `01_Projects/AISobolev - блог buildinpublic/Published Posts/RU/`
- **Published EN:** `01_Projects/AISobolev - блог buildinpublic/Published Posts/EN/`

### When saving the post

- Save drafts to `Draft Posts/RU/` (or `EN/`) by default.
- Move to `Published Posts/` only when the user explicitly says to publish.

## Post Templates

### Published Post (Telegram single-version)

```markdown
# Заголовок поста

_DD месяц YYYY_

---

[Хук: 1-2 предложения. Противоречие, интрига, цифра или личная история.]

[Проблема: 1-3 абзаца. Что не так? Почему текущий подход не работает? Личный опыт.]

[Рефрейм: 1-3 абзаца. Почему общепринятое мнение неполно. Ваш взгляд из опыта. Конкретные примеры, цифры, кейсы.]

[Действие: 1-2 абзаца. Что вы делаете / что изменилось. Приглашение к диалогу.]

[Закрытие: вопрос к читателю или emoji-реакция]
```

**Примеры закрытий:**
- `А вы как нашли своего первого клиента? 👇`
- `🤓 если уже зарабатываете на своём 🗿 если пока в найме`
- `👍 если да, 👎 если нет`
- `Вопрос к вам: что вас останавливает от запуска? 👇`

### Draft Post (с метаданными)

```markdown
# Заголовок поста

**Платформа:** Telegram / Threads / X / LinkedIn
**Статус:** Черновик
**Дата:** YYYY-MM-DD
**Связанный проект:** [[Название проекта]]
**Источник:** [[Research/название-исследования]]

---

[Текст поста]
```

### Draft Post (мульти-версия для нескольких платформ)

```markdown
# Заголовок поста

_DD месяц YYYY_

---

## Версия для Telegram (RU)

[Текст: абзацы 2-4 строки, markdown поддерживается, более неформально]

---

## Версия для Threads (RU)

[Текст: max 500 символов, plain text, 3-5 хештегов, одна мысль]

---

## Версия для X (EN)

[Tweet 1: Hook — under 280 chars, English]
[Tweet 2-N: Value delivery, one point per tweet]
[Final tweet: Takeaway + follow CTA]

---

## Версия для LinkedIn (опционально)

[Текст: короткие абзацы 1-2 строки, → стрелки для списков, без H2/H3, без em-dashes]
```

### Structured Post (секции с emoji-заголовками)

Для длинных образовательных постов:

```markdown
# Заголовок поста

_DD месяц YYYY_

---

[Хук]

🧐 Проблема / Контекст

[Описание проблемы]

🤔 Что с этим делать?

[Рефрейм / решение]

😎 Мой пример

[Личный кейс с конкретикой]

😑 Почему это работает

[Обоснование]

🚀 С чего начать

[Практические шаги]

🔜 [Закрытие с вопросом или emoji-реакцией]
```

### Listicle Post (numbered myths / points)

```markdown
# Заголовок поста

_DD месяц YYYY_

---

[Хук с цифрой: "95% пилотов проваливаются" / "5 мифов, которые убивают проекты"]

---

1️⃣ **Пункт первый**

[Объяснение с примером]

2️⃣ **Пункт второй**

[Объяснение с примером]

3️⃣ **Пункт третий**

[Объяснение с примером]

---

[Закрытие: вывод + вопрос]
```

## Resources

- [Hooks Guide](resources/hooks-guide.md)
- [Style Guide](resources/style-guide.md)
- [Threads Guide](resources/threads-guide.md)
- [X (English) Guide](resources/x-guide.md)
