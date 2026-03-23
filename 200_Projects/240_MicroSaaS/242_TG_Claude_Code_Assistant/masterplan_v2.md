# TG Claude Code Assistant — Masterplan v2: Расширение функционала

## Контекст

Фазы 1 (MVP: текстовый мост, Obsidian, YouGile, авторизация, фото/файлы) и 2 (голосовые, медиа) — **реализованы и работают**. Данный документ описывает следующий этап развития бота.

**Два направления расширения:**
1. Контекстная маршрутизация контента (новая фича)
2. Проактивность и шорткаты (Фаза 3 из оригинального masterplan)

---

## Направление 1: Контекстная маршрутизация контента

### Суть

Бот анализирует входящий контент (ссылка, пересланное сообщение, файл, текст), определяет его тип, автоматически выполняет действие по умолчанию и предлагает дополнительные действия — включая вызов подходящих навыков (skills).

### Проблема сейчас

Бот обрабатывает всё как чат-запрос к Claude. Пользователь должен явно указывать "сохрани как заметку" или "создай задачу". Навыки (youtube-summary, inbox-processor и др.) не вызываются автоматически — нужно знать и писать команду.

### Целевое поведение

```
Пользователь скидывает контент
       ↓
[Content Analyzer] — определяет тип контента
       ↓
[Action Router] — выбирает дефолтное действие + навык
       ↓
[Executor] — выполняет действие
       ↓
[Follow-up Proposer] — предлагает доп. действия (inline-кнопки)
```

### Матрица маршрутизации

| Входящий контент | Как определить | Дефолтное действие | Навык (skill) | Доп. действия (кнопки) |
|---|---|---|---|---|
| YouTube ссылка | Regex: `youtube.com/watch`, `youtu.be/` | Сохранить ссылку в inbox | `/youtube-summary` | Саммари, Задачу из видео, В проект |
| Ссылка на статью | URL без youtube/github паттернов | Сохранить в inbox + краткое описание | — (Firecrawl для скрейпинга) | Полный саммари, Задачу, В проект |
| GitHub ссылка | `github.com/` | Сохранить в inbox | — | Проанализировать репо, Задачу |
| Пересланное сообщение | `message.forward_from` / `forward_origin` | Сохранить в inbox как заметку | — | Создать задачу, Извлечь контакты, В проект |
| Голосовое сообщение | `message.voice` | Транскрипция → сохранить в inbox | — | Создать задачу, В заметку, Брейншторм |
| Фото/скриншот | `message.photo` | Сохранить + анализ (Gemini Vision) | — | В заметку с описанием, OCR текста |
| Документ/файл | `message.document` | Сохранить на VPS + описание | — | Проанализировать, Саммари, В проект |
| Текст с явным запросом | NLP-анализ ("добавь задачу", "запиши") | Роутинг по ключевым словам | По контексту | Подтверждение + альтернативы |
| Текст без явного запроса | Всё остальное | Чат с Claude (текущее поведение) | — | — |

### Детали реализации Content Analyzer

**Уровень 1 — Детерминистический (regex + тип сообщения):**
- URL-паттерны: YouTube, GitHub, Twitter/X, Medium, Habr
- Тип сообщения Telegram API: voice, photo, document, forward
- Ключевые слова: "задача", "запиши", "напомни", "сохрани"

**Уровень 2 — LLM-классификация (для неоднозначных случаев):**
- Если Уровень 1 не дал точного ответа — короткий запрос к Claude для классификации
- Промпт: "Определи тип контента и рекомендуемое действие: [контент]"
- Кэшировать паттерны для повторяющихся типов

### Механизм Follow-up Actions

После выполнения дефолтного действия бот отправляет сообщение с inline-кнопками:

```
✅ Ссылка сохранена в inbox: "Название статьи"

Что ещё сделать?
[📝 Полный саммари] [📋 Создать задачу] [📁 В проект...]
```

**Для YouTube-ссылок:**
```
✅ Ссылка сохранена в inbox: "Название видео"

Что ещё сделать?
[🎬 YouTube саммари] [📋 Задачу из видео] [📁 В проект...]
```

**Кнопка "В проект..."** — показывает второй ряд кнопок со списком активных проектов из `200_Projects/`.

### Навыки (Skills) — автоматический вызов

Ключевая идея: бот знает о доступных навыках и вызывает их контекстно.

**Маппинг контент → навык:**

| Контент | Навык | Условие автовызова |
|---|---|---|
| YouTube URL | `/youtube-summary` | По кнопке "YouTube саммари" |
| Любой текст для обработки | `/inbox-processor` | Когда контент нужно рассортировать |
| Запрос на ресёрч | `/research-assistant` | По ключевым словам или кнопке |
| Текст поста | `/de-ai-ify` | По кнопке при редактировании контента |
| Запрос на брейншторм | `/brainstorming` | По ключевым словам |

**Навыки НЕ вызываются автоматически** — только по нажатию кнопки или явному запросу. Автоматически выполняется только дефолтное действие (сохранение).

---

## Направление 2: Проактивность и шорткаты

### 2.1 Проактивные уведомления

**Утренний дайджест (ежедневно, настраиваемое время):**
```
🌅 Доброе утро, Сергей!

📋 Задачи на сегодня (YouGile):
• [Задача 1] — дедлайн сегодня ⚠️
• [Задача 2] — в работе
• [Задача 3] — ожидает

📥 Inbox: 3 необработанных элемента

💡 Напоминание: Еженедельная сводка через 2 дня
```

**Напоминания о дедлайнах:**
- За 1 день до дедлайна — уведомление
- В день дедлайна — утром в дайджесте + отдельное напоминание
- Просроченные — ежедневно до обработки

**Реализация:**
- Cron-задачи на VPS (systemd timers или crontab)
- Скрипт собирает данные: YouGile API → задачи, git repo → inbox count
- Отправка через Telegram Bot API (не через Claude Code — для скорости)
- Конфиг расписания в `~/.config/tg-claude-bot/notifications.yaml`

```yaml
notifications:
  morning_digest:
    enabled: true
    time: "09:00"
    timezone: "Asia/Almaty"
    users: [USER_ID_1, USER_ID_2]
  deadline_reminder:
    enabled: true
    advance_days: 1
  overdue_check:
    enabled: true
    time: "10:00"
```

### 2.2 Команды-шорткаты

Быстрые команды для частых действий без полного диалога с Claude:

| Команда | Действие | Реализация |
|---|---|---|
| `/tasks` | Задачи на сегодня из YouGile | YouGile API → фильтр по дедлайну |
| `/inbox` | Количество и список элементов inbox | `ls 000_Inbox/` → count + list |
| `/daily` | Запустить daily review | Вызов навыка `/daily-review` через Claude Code |
| `/week` | Недельная сводка | Вызов навыка `/weekly-synthesis` через Claude Code |
| `/projects` | Список активных проектов + статус | `ls 200_Projects/` + YouGile boards |
| `/quick <текст>` | Быстрая заметка в inbox без диалога | `echo > 000_Inbox/YYYY-MM-DD_quick.md` |

**Реализация шорткатов:**

Два типа по скорости:
1. **Быстрые** (`/tasks`, `/inbox`, `/quick`) — прямой вызов API/файловой системы, без Claude Code. Ответ за 1-2 секунды.
2. **Полные** (`/daily`, `/week`) — через Claude Code CLI с вызовом навыка. Ответ за 15-30 секунд, с индикатором "typing...".

### 2.3 Еженедельная сводка

Автоматическая (воскресенье вечером или понедельник утром) или по команде `/week`:

```
📊 Неделя 5 февраля — 11 февраля

✅ Завершено: 12 задач
📋 В работе: 5 задач
⚠️ Просрочено: 2 задачи

📝 Заметок создано: 8
📥 Inbox обработано: 15 элементов

🔥 Топ-проект недели: AGIents.pro (7 задач)

💡 На следующую неделю:
• 3 дедлайна
• 2 просроченных задачи требуют внимания
```

---

## Технические решения

### Архитектура Content Analyzer

```
Telegram Message
       ↓
[Message Handler] — извлекает: text, entities, media, forward_info
       ↓
[Content Classifier] — Level 1: regex/type → Level 2: LLM fallback
       ↓
[Action Resolver] — определяет: default_action + available_actions + skill
       ↓
[Action Executor]
   ├── save_to_inbox(content, metadata)
   ├── call_skill(skill_name, args)
   ├── create_task(title, project)
   └── chat_with_claude(message)
       ↓
[Response Builder] — текст результата + inline keyboard
       ↓
Telegram Reply
```

### Новые компоненты

| Компонент | Описание | Файл |
|---|---|---|
| `ContentClassifier` | Определение типа контента (regex + LLM fallback) | `classifiers/content.py` |
| `ActionRouter` | Маппинг тип → действие + навык | `routing/actions.py` |
| `SkillInvoker` | Вызов Claude Code skills из бота | `skills/invoker.py` |
| `InlineKeyboardBuilder` | Генерация кнопок follow-up действий | `ui/keyboards.py` |
| `CallbackHandler` | Обработка нажатий inline-кнопок | `handlers/callbacks.py` |
| `NotificationScheduler` | Cron-планировщик уведомлений | `notifications/scheduler.py` |
| `ShortcutHandler` | Обработка быстрых команд | `handlers/shortcuts.py` |
| `DigestBuilder` | Сборка утреннего дайджеста / недельной сводки | `notifications/digest.py` |

### Конфиг маршрутизации

```yaml
# routing_config.yaml
content_routing:
  youtube:
    patterns:
      - 'youtube\.com/watch'
      - 'youtu\.be/'
      - 'youtube\.com/shorts/'
    default_action: save_to_inbox
    skill: youtube-summary
    follow_up:
      - { label: "🎬 YouTube саммари", action: "call_skill", skill: "youtube-summary" }
      - { label: "📋 Создать задачу", action: "create_task" }
      - { label: "📁 В проект...", action: "select_project" }

  article:
    patterns:
      - 'https?://(?!youtube|github|t\.me).*'
    default_action: save_to_inbox_with_summary
    follow_up:
      - { label: "📝 Полный саммари", action: "scrape_and_summarize" }
      - { label: "📋 Создать задачу", action: "create_task" }
      - { label: "📁 В проект...", action: "select_project" }

  forwarded_message:
    trigger: message_is_forwarded
    default_action: save_to_inbox
    follow_up:
      - { label: "📋 Создать задачу", action: "create_task" }
      - { label: "📇 Извлечь контакты", action: "extract_contacts" }
      - { label: "📁 В проект...", action: "select_project" }

  voice:
    trigger: message_has_voice
    default_action: transcribe_and_save
    follow_up:
      - { label: "📋 Создать задачу", action: "create_task" }
      - { label: "📝 В заметку", action: "save_as_note" }
      - { label: "🧠 Брейншторм", action: "call_skill", skill: "brainstorming" }

  photo:
    trigger: message_has_photo
    default_action: save_and_analyze
    follow_up:
      - { label: "📝 В заметку с описанием", action: "save_with_description" }
      - { label: "🔤 OCR текста", action: "ocr_extract" }
```

### Хранение состояния inline-кнопок

Callback data в Telegram ограничена 64 байтами. Решение:
- Короткие callback ID: `act:yt_sum:msg123`
- Маппинг ID → полный контекст в SQLite (существующая БД сессий)
- TTL на записи: 24 часа (после этого кнопки перестают работать)

---

## Модель данных (расширение)

### Новые сущности

- **ContentAction** — action_id, message_id, content_type, default_action, status, created_at
- **FollowUpCallback** — callback_id, action_id, action_type, skill_name, params (JSON), expires_at
- **NotificationConfig** — user_id, type (digest/deadline/overdue), schedule (cron), enabled, last_sent
- **NotificationLog** — notification_id, user_id, type, content, sent_at, status

### Расширение существующих

- **Message Log** — добавить: `content_type` (youtube/article/forward/voice/photo/text), `routed_action`, `skill_invoked`

---

## Этапы реализации

### Этап 3.1: Контекстная маршрутизация (ядро)

- [ ] Реализовать `ContentClassifier` — regex-паттерны для URL (YouTube, GitHub, статьи)
- [ ] Реализовать `ActionRouter` — маппинг тип контента → действие
- [ ] Реализовать сохранение в inbox с метаданными (тип, источник, дата)
- [ ] Добавить inline-кнопки follow-up действий
- [ ] Реализовать `CallbackHandler` для обработки нажатий кнопок
- [ ] Тестирование: YouTube ссылка, обычная ссылка, пересланное сообщение

### Этап 3.2: Интеграция навыков

- [ ] Реализовать `SkillInvoker` — вызов Claude Code skills по кнопке
- [ ] Интегрировать `/youtube-summary` — по кнопке для YouTube-ссылок
- [ ] Интегрировать Firecrawl — скрейпинг и саммари статей по кнопке
- [ ] Добавить обработку фото через пересланные сообщения (forward + photo)
- [ ] Тестирование полного цикла: ссылка → сохранение → кнопка → навык → результат

### Этап 3.3: Проактивные уведомления

- [ ] Реализовать `NotificationScheduler` (cron на VPS)
- [ ] Утренний дайджест: сбор задач из YouGile + inbox count
- [ ] Напоминания о дедлайнах (за 1 день, в день)
- [ ] Конфиг уведомлений в YAML
- [ ] Тестирование: ручной запуск дайджеста, проверка расписания

### Этап 3.4: Команды-шорткаты

- [ ] `/tasks` — быстрый запрос YouGile без Claude Code
- [ ] `/inbox` — быстрый подсчёт и список inbox
- [ ] `/quick <текст>` — мгновенная заметка
- [ ] `/daily` — вызов daily-review через Claude Code
- [ ] `/week` — вызов weekly-synthesis через Claude Code
- [ ] `/projects` — список проектов со статусом

### Этап 3.5: Еженедельная сводка

- [ ] `DigestBuilder` — сбор статистики за неделю
- [ ] Автоматическая отправка по расписанию
- [ ] Интеграция с `/week` командой

---

## Потенциальные вызовы и решения

| Вызов | Влияние | Решение |
|---|---|---|
| Неправильная классификация контента | Бот делает не то действие | Двухуровневая классификация (regex → LLM fallback). Кнопка "Это не то" для коррекции |
| Callback data лимит 64 байта | Не влезает контекст действия | Короткие ID + SQLite маппинг с TTL |
| Навык выполняется долго (30+ сек) | Пользователь не понимает что происходит | Индикатор "typing...", промежуточное сообщение "Обрабатываю YouTube-видео..." |
| Cron на VPS может сбоиться | Дайджест не приходит | Логирование + health-check: если дайджест не отправлен за 30 мин после расписания — алерт |
| Inline-кнопки устаревают | Нажатие на старую кнопку не работает | TTL 24 часа, при нажатии на expired — "Действие устарело, отправьте контент заново" |
| Два пользователя нажимают кнопки одновременно | Конфликт сессий Claude Code | Очередь обработки (уже реализована в MVP) |

---

## Метрики успеха

- **Контекстная маршрутизация:** >80% контента корректно классифицируется без LLM fallback
- **Follow-up кнопки:** >50% сообщений с кнопками получают нажатие (значит кнопки полезны)
- **Дайджест:** ежедневная доставка без пропусков в течение 2 недель
- **Шорткаты:** `/tasks` и `/inbox` — ответ < 3 секунд

---

*Расширение masterplan v1. Создано с помощью /prd*
