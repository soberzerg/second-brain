---
type: note
date: 2026-04-08
tags: [log, wiki-meta]
status: active
---

# Operations Log

> Хронологический лог операций над хранилищем. Append-only.
> Формат: `## [YYYY-MM-DD] <operation> | <Title>` — grep-parseable.
> Операции: ingest, create, update, lint, query.

## [2026-05-08] create | КП для svet.kz — AI-агент квалификации лидов на AGIents (Instagram + WhatsApp + Bitrix24)

- Files created:
  - 200_Projects/210_AGIency/216_Clients/Svet.kz/proposal.md
- Files updated: index.md, log.md
- Details: Подготовлено КП **от имени Clario** для svet.kz (розничный магазин освещения, Казахстан, ~125k SKU). Контекст: знакомство на выставке + встреча, входящий поток 2 000 обращений/мес в Instagram + WhatsApp (уже подключены к Bitrix24 через Открытые Линии), главная боль — обращения в нерабочее время теряются, при этом клиент готов масштабировать рекламный трафик. Скоуп бота на Этапе 1 — только квалификация и передача чата менеджеру (без товарного подбора по 125k SKU); набор квалифицирующих вопросов будет согласован с клиентом на стартовом Discovery. Режим работы 24/7 (бот первой линией для всех), при квалификации — создание лида в Bitrix24 + бот зовёт менеджера в чат. Платформа AI-агента — **Clario.Agents** (ребрендинг AGIents). Модель — фикс за внедрение Этапа 1 → подписка по токенам **50 000 ₸/мес, квота 50 000 000 токенов (≈ 2 000–3 000 диалогов), перерасход 500 ₸ за 1 000 000 токенов**; биллинг по фактическому расходу токенов вместо диалогов — прозрачно и не зависит от длины переписки. **2026-05-10:** убраны два пакета пилота (M/L), вместо них зафиксирована единая дорожная карта из 4 этапов: (1) розница, свет — текущее предложение; (2) розница, краски — тот же тип агента; (3) B2B, свет — ИИ-менеджер с поиском в каталоге и оформлением заявок постоянных клиентов; (4) B2B, краски — то же для красок. Этапы 2–4 — отдельные доп. соглашения с пересчётом цены и квоты, запускаются последовательно после стабилизации предыдущего. Все коммерческие цифры (стоимость внедрения Этапа 1, график платежей, SLA, дата старта, ФИО ЛПР, точные KPI, ориентиры по бюджетам/срокам Этапов 2–4, каналы B2B) проставлены как [TODO] — заполняются перед отправкой клиенту. Документ построен по шаблону resources/proposal-template.md, включает все 10 секций + frontmatter + связанные документы (Кейс Amaks, Platform Capabilities, Договор техподдержки шаблон). Создана новая клиентская папка 216_Clients/Svet.kz/.

## [2026-05-07] create | Шаблон договора на техподдержку AGIents + ревью КП Amaks (M/L)

- Files created:
  - 200_Projects/220_AGIents/225_BizDev/Договор техподдержки - шаблон.md
- Files reviewed:
  - 200_Projects/210_AGIency/216_Clients/Amaks/Расчёт_ Интеграция ИИ-бота с amoCRM - Поддержка M.csv
  - 200_Projects/210_AGIency/216_Clients/Amaks/Расчёт_ Интеграция ИИ-бота с amoCRM - Поддержка L.csv
- Details: Создан рамочный шаблон договора на техподдержку ИИ-агента под платформу AGIents.pro — 15 разделов + 5 приложений (Тариф, Объекты/интеграции, SLA, Доступы, ПДн). Шаблон тариф-агностичен: ссылается на Приложение №1 (Тариф S/M/L/XL), что позволяет переиспользовать его для любого клиента. Включает: ИП/УСН и НДС-плейсхолдеры, индексацию по ИПЦ, лимит ответственности (3 отчётных периода), оговорку о галлюцинациях LLM, разграничение ИС (Платформа — Исполнителю, контент Базы знаний — Заказчику, конфигурация — TODO согласовать), ФЗ-152 как поручение Оператора, передачу+удаление данных при расторжении, ЭДО, smoke-friendly формулировки. Параллельно сделан разбор CSV-расчётов M (25 000 ₽) и L (40 000 ₽) — найдено 7 проблем: внутреннее противоречие про мониторинг в M, отталкивающие формулировки "не ведем"/"не проводим", отсутствие лимитов в M, отсутствие SLA-различий между M и L, отсутствие периода/валюты/НДС/ставки часовых работ в шапке таблицы, неравномерный шаг M→L (+10K за бота, +5K за базу), отсутствие тарифа-якоря (рекомендую добавить S и XL).

## [2026-05-04] ingest | AGIency Design System v1.0

- Source: 000_Inbox/AGIency_design_system_v1.docx
- Destination: 200_Projects/210_AGIency/217_Brand/
- Files created:
  - 200_Projects/210_AGIency/217_Brand/Design System v1.md
  - 200_Projects/210_AGIency/217_Brand/README.md
- Files updated: index.md, log.md
- Details: Полный бренд-документ AGIency v1.0 с .docx переведён в Markdown. 9 секций: основа бренда (формула Понимание→Конструкция→Результат, архетипы Мудрец/Творец/Герой), 5 принципов (системность, минимализм, инженерность, фокус на результате, читаемость), цветовая палитра (фон #FAF8F5, графит #1F1F1F, акцент красный #E53935 — отказ от фиолетового и AI-клише), типографика (Manrope), логотип (выделение AGI с красной точкой в A), UI-язык (схемы/оси/сетки, тонкие границы), тон коммуникации, запреты (нет градиентам/неону/3D), формула «светлая база + инженерная строгость + один сильный акцент». Создана новая поддиректория 217_Brand/ для брендовых материалов AGIency. Source-файл .docx оставлен в Inbox (бинарный оригинал может пригодиться).

## [2026-04-30] create | Контент-план на 30 дней — май 2026

- Files created:
  - 300_Blog/315_Content_Plans/2026-04-30 Контент-план на 30 дней (май 2026).md
- Files updated: index.md, log.md
- Details: Goal #16 / task #33 (AgentOS orchestrator). Собран месячный контент-план для AISobolev на 01.05–30.05.2026 на основе существующего контекста vault — без запросов к пользователю. Опора: [[Карта экспертности]], [[Нейроанализ ЦА - Фаундеры]] (80%), [[Нейроанализ ЦА - Директора МСБ]] (20%), [[Упаковка блога]], [[Система контента]], [[Оффер и продуктовая линейка]], [[Руководство - Диагностирующий блог]], [[2026 Yearly Plan]], [[2026-03-16 Threads Strategy]], публикационный пакет [[instagram-carousels-final-10]]. Структура: резюме стратегии, 8 бизнес-целей с метриками (TG 210→350+, Threads 297→500+, лид-магниты 25–40, трипваеры 4–6 шт.), 5 пилларов с пропорциями (Диагностика 28% / Кейсы 22% / Buildinpublic 22% / Мнение 18% / Продающий 10%), рубрикатор по дням недели, 4 тематические недели (Реальность ИИ / Цифры / AGIents.pro buildinpublic / Позиция и приглашение), календарь на 30 дней по платформам с CTA, банк хуков для 17 TG-постов, паттерны Threads, 4 запланированные Instagram-карусели (3 готовы, 4-я — Opus/Sonnet/Haiku — нужно создать к 26.05), repurposing-схема TG→Threads/X/LinkedIn/Insta с бюджетом 5.8–8.3 ч/нед, лид-магниты МОЗГ/ДИАГНОЗ/GIT с воронкой до ретейнера, метрики для ретро 30.05, чеклист запуска. Явно зафиксированы 9 допущений и пробелов vault: базовые цифры подписчиков, статус ботов, согласия клиентов на кейсы, цены аудита, baseline метрик X/LinkedIn, риск раскрытия закрытых проектов AgentOS Phase 2 / Ralph Loop. Тип создан как `content-plan`, размещён в новой поддиректории 300_Blog/315_Content_Plans/ (между 310 идеями и 320 контекстом). Привязка к Q2-плану из [[2026 Yearly Plan]]: рост подписчиков и лидов под запуск AGIents.pro.

## [2026-04-29] query | Agentic OS — приоритизация фич сообществом

- Files created:
  - 500_Research/520_Social_Research/2026-04-29 - Agentic OS - Приоритизация фич сообществом.md
- Files updated: index.md, log.md
- Details: Reddit r/artificial пост u/ramirez_tn про governed multi-agent execution platform (score 0, ratio 0.44, 13 комментариев). Дословно собран пост и все 12 валидных комментариев через MCP reddit-search + JSON endpoint (MCP-выжимка скрывала score'ы и часть текста). Сформирована приоритизация фич по силе валидации сообществом: P0 (zero shared state + structured handoffs, governance/RBAC + audit log) — 4 положительных голоса; P1 (HITL operator console с RBAC-scoped monitoring — pab_guy; прозрачная escalation policy — Low_Blueberry_6711) — конкретные просьбы расширить; P2 (reputation scoring, task versioning, evaluation engine) — упомянуто автором, не отрефлексировано сообществом, риск over-engineering; P3 (team presets, 5-слойная архитектура) — стандартное, не дифференциатор. Рекомендации: фокус на P0+P1 в demo/landing (audit-trail визуализация + operator console с HITL queue), опубликовать DSL/YAML для escalation policy, отложить reputation scoring и evaluation engine. Ключевое наблюдение: ratio 0.44 = silent-аудитория голосует против, поэтому положительные комментарии не = полная валидация рынка.

## [2026-04-29] create | Санатории — ручное исследование гипотез поиска контактов ЛПР

- Files created:
  - 200_Projects/220_AGIents/222_Research/Санатории - Ручное исследование гипотез поиска контактов ЛПР.md
- Files updated: index.md, log.md
- Details: Goal #15 / task #31 (AgentOS orchestrator). Зафиксирована выборка из 5 санаториев (Машук Аква-Терм, СКК Знание, Янган-Тау, Загорские дали, Полтава-Крым) — разные регионы, размеры, формы собственности. Прогнаны 11 гипотез поиска ЛПР без платных enrichment: H1 офсайт, H2 RusProfile/checko, H3 zakupki.gov.ru, H4 PDF, H5–H7 соцсети (VK/Telegram/Instagram/OK/Дзен/MAX/YouTube), H8 hh.ru, H9 LinkedIn, H10 email-шаблоны, H11 СМИ/интервью. Для каждой гипотезы зафиксированы шаги, объём просмотренного, yield по выборке, типы получаемых контактов, ограничения. Сведена таблица контактов на ~70 строк по 5 санаториям с метками direct/fallback и confidence high/medium/low; для каждой записи указан источник (URL или конкретная страница). Главный наблюдённый разрыв: 0/5 прямых персональных каналов CEO/директора по продажам, но 5/5 ФИО формальных руководителей и 5/5 близких к ЛПР каналов отделов (sales@/marketing@/b2b@/market@). Рекомендации: автоматизировать H1+H2+H10 как базовый слой (DaData + парсинг офсайтов + Hunter.io), H8 как сигнал зрелости, H11 оставить ручным на топ-N аккаунтов перед outreach, LinkedIn для РФ-санаториев не подключать. Все ФИО/email-ы взяты из открытых источников; противоречия (Машук — Боков vs Карлова; Полтава — Попов vs Ракоцило) явно помечены как low confidence.

## [2026-04-29] create | Instagram-карусель «5 ИИ-агентов экономят соло-фаундеру 10 ч/нед» — драфт + 6 PNG

- Files created:
  - 300_Blog/350_Draft_Posts/351_RU/2026-04-29 Instagram-карусель 5 ИИ-агентов соло-фаундеру.md
  - 300_Blog/390_Images/2026-04-29-5-ai-agents-solo-founder/slide-01-cover.png (1080×1350)
  - 300_Blog/390_Images/2026-04-29-5-ai-agents-solo-founder/slide-02-research-agent.png (1080×1350)
  - 300_Blog/390_Images/2026-04-29-5-ai-agents-solo-founder/slide-03-inbox-agent.png (1080×1350)
  - 300_Blog/390_Images/2026-04-29-5-ai-agents-solo-founder/slide-04-content-agent.png (1080×1350)
  - 300_Blog/390_Images/2026-04-29-5-ai-agents-solo-founder/slide-05-sales-agent.png (1080×1350)
  - 300_Blog/390_Images/2026-04-29-5-ai-agents-solo-founder/slide-06-analytics-agent.png (1080×1350)
- Files updated: index.md, log.md
- Details: Goal #13 / task #27 (AgentOS orchestrator). Развёрнут outline темы #8 из публикационного пакета `instagram-carousels-final-10` в готовый к публикации markdown-черновик и шесть слайдов карусели. Структура: обложка + 5 ролей агентов (Research, Inbox, Контент, Sales, Analytics) с разбивкой по часам — 2 + 2 + 3 + 2 + 1 = 10 ч/нед, CTA встроен в последний слайд. Caption в стиле AISobolev (личный тон, конкретные часы, итоговое уравнение, вопрос в финале). 12 хэштегов RU/EN. Изображения сгенерированы через nano-banana (Gemini 2.5 Flash Image), единая палитра — deep navy #0E1525 + emerald #10B981, минимализм, крупный читаемый Cyrillic, без stock-клише и без отсылок к Claude Code/CLAUDE.md. Все артефакты приведены к точному размеру 1080×1350 (sips), формат PNG. Тема выдержана сквозь markdown, caption, hashtags, prompt'ы и сами изображения.

## [2026-04-28] create | Instagram-карусель CLAUDE.md 10 секций — финальный текст

- Files created: 300_Blog/350_Draft_Posts/351_RU/2026-04-28 Instagram-карусель CLAUDE.md 10 секций.md
- Files updated: index.md, log.md
- Details: Goal #12 / task #23 (AgentOS orchestrator). Развёрнут outline темы #2 из публикационного пакета (instagram-carousels-final-10) в готовый к публикации markdown-черновик: 10 слайдов по 15–60 слов (обложка + структура / команды / code style / тестирование / безопасность / hooks / агенты / выбор модели + CTA), Instagram-подпись 248 знаков, 8 хэштегов (#claudecode #claude #vibecoding #вайбкодинг #aiagents #aiфаундер #нейросети #aiproductivity). Все тексты без placeholder'ов, в стиле AISobolev (короткие предложения, конкретика, без корпоративного жаргона), готовы к копированию в редактор каруселей.

## [2026-04-28] create | Instagram-карусели для сохранений — публикационный пакет 10 тем

- Files created: 300_Blog/310_Content_Ideas/instagram-carousels-final-10.md
- Files updated: log.md
- Details: Goal #11 / task #19 (AgentOS orchestrator). Финальный публикационный пакет на основе отбора task #18: 10 тем оформлены едиными подпунктами «заголовок с цифрой / причина сохраняемости / количество слайдов». Распределение по форматам: чек-лист 2 / пошаговая 3 / подборка 3 / сравнение 2. Слайды подобраны по плотности контента в рамках ориентиров (чек-лист 7-10, пошаговые 8-12, подборки 10-12, сравнения 6-8).

## [2026-04-28] create | Instagram-карусели для сохранений — финальный отбор 10 тем

- Files created: 300_Blog/310_Content_Ideas/2026-04-28 Instagram-карусели для сохранений - 10 тем.md
- Files updated: index.md, log.md
- Details: Goal #11 / task #18 (AgentOS orchestrator). Из пула предыдущей подзадачи отобрано 10 тем для Instagram-каруселей с ориентацией на сохранения. Покрыты все 4 требуемых формата: 2 чек-листа (12 пунктов перед MVP, 10 секций CLAUDE.md), 3 пошаговых (первый Claude skill за 30 минут, Ralph Loop на ночь, 4 уровня памяти агента), 3 подборки (7 ежедневных skills, 10 промптов соло-фаундера, 5 экономящих 10 ч/нед агентов), 2 сравнения (Opus/Sonnet/Haiku, Cursor/Claude Code/Aider). Для каждой темы зафиксирован формат + обоснование.

## [2026-04-28] ingest | Лайфхаки при создании Claude Code skills

- Source: 000_Inbox/Лайфхаки при создании skills.md
- Destination: 500_Research/550_AI/551_Agents/Лайфхаки при создании Claude Code skills.md
- Files created: 500_Research/550_AI/551_Agents/Лайфхаки при создании Claude Code skills.md
- Files updated: index.md, log.md
- Details: Конденсированный чеклист из 20 правил по созданию качественных Agent Skills на основе официальной доки Anthropic (Skill authoring best practices + Agent Skills overview). Покрывает naming, description с триггерами, progressive disclosure, workflow по шагам, output templates, examples, validation loop, scripts для детерминированных операций, dependencies, тесты на 3+ сценариях. Применимо к аудиту существующих custom skills и обучению клиентов AGIency. Кандидат на Threads-лонгрид и материал для AI Coding Training в Dogovor24

## [2026-04-28] ingest | Own Your Harness — Sau Sheong (Medium)

- Source: 000_Inbox/2026-04-28 08.04.30 Own Your Harness What compaction in Claude Code a.txt
- Destination: 500_Research/550_AI/551_Agents/Own Your Harness - Sau Sheong.md
- Files created: 500_Research/550_AI/551_Agents/Own Your Harness - Sau Sheong.md
- Files updated: index.md, log.md
- Details: Глубокий разбор compaction-стратегий в Claude Code и OpenClaw как иллюстрация того, почему harness — ключевой дифференциатор продукта, а не "тонкая обёртка над моделью". Документирует 8 механизмов compaction в Claude Code, противоположный preemptive-подход OpenClaw, разницу в schema (narrative vs structural), recovery (lossy + circuit breaker vs snapshot + cancel), memory (substitute vs supplement). Содержит цифры из production telemetry Anthropic: "1,279 sessions с 50+ failures, ~250K API calls/день", "2.79% vs 0.01% tool calls во время compaction Sonnet 4.6 vs 4.5". Прямое применение к проекту orchestrator (AGIents) — готовый чеклист дизайн-решений для собственного harness. Сильный кандидат на блог-пост на русском

## [2026-04-20] create | Threads тред — Harness становится продуктом

- Files created: 300_Blog/350_Draft_Posts/351_RU/2026-04-20 Harness становится продуктом - Threads.md
- Files updated: index.md, log.md
- Details: Тред из 8 постов для Threads на базе 2026-04-20 AI Daily Digest и анализа Jensen Huang 5-layer cake. Хук — reverse-engineering Claude Code: 98.4% harness, 1.6% AI. Основная мысль — продукт это оркестрация, permissions, tools, memory, workflow, UX, инфра вокруг модели; модель должна быть подставляемым компонентом. Привязка к AgentOS как model-agnostic-продукту и к запуску анонса (2026-04-20). CTA — собрать у аудитории описание их harness для следующего разбора. Новый файл, черновик 04-16 не затирается (другой угол — Clario)

## [2026-04-20] create | AI Daily Digest — vault-based для фаундера/CTO

- Files created: 500_Research/510_AI_Daily_Digest/2026-04-20 - AI Daily Digest.md
- Files updated: index.md, log.md
- Details: Vault-based digest за 2026-04-16 — 2026-04-20 (без прямого доступа к X/Reddit/web). Секции: Что важно сегодня, Модели/продукты, Open source/инфраструктура, Что это значит для Clario/AGIency, 3 action items. Ключевые темы: harness > model (reverse-engineering Claude Code), vendor lock-in (кейс Anthropic ban), cost management multi-agent (5 часов кредитов / 32 мин), форк Claude Code под GPT/Gemini/DeepSeek, Salesforce Headless 360 (MCP), слухи о параллельных релизах Opus 4.7 и новой Opus-class модели OpenAI. Action items: (1) добавить model-agnostic + cost controls в AGIents Platform Capabilities и шаблон КП, (2) прописать многопровайдерный LLM-слой в Clario v2 RoadMap и Bazis PRD, (3) выложить Threads-тред «harness важнее модели» на базе готового черновика

## [2026-04-20] create | Коммерческое предложение для Krytex

- Files created: 200_Projects/210_AGIency/216_Clients/Krytex/proposal.md
- Files updated: index.md, log.md
- Details: КП на базе PRD — setup 450 000 ₽ (30/40/30 по трём фазам), подписка 5 ₽/запрос без минимума, warranty 30 дней, 6 недель внедрения. CTA — подписать и оплатить аванс 135k до 2026-05-04. Кейсы не использованы (акцент на платформе AGIents), команда без фамилий. TODO: добавить контакты в секции 10

## [2026-04-20] create | PRD Krytex bot + AGIents Platform Capabilities

- Files created: 200_Projects/210_AGIency/216_Clients/Krytex/prd.md, 200_Projects/220_AGIents/Platform Capabilities.md
- Files updated: index.md, log.md
- Details: PRD бота для Krytex на платформе AGIents — Telegram/VK/MAX + маркетплейс-pipeline Ozon/WB, редактор Q&A, лог escalations, 3 фазы по 2 недели. Зафиксированы текущие возможности AGIents (Inbox, Аналитика, Настройки, Пользователи, Сессионная память) отдельным документом для скоупинга клиентских проектов

## [2026-04-19] create | YouTube Summary — I Built My First AI Employee

- Source: <https://youtu.be/zFM5elMy5Do?si=2ncCvgr_Ol2GewKm>
- Files created: 500_Research/530_YouTube/2026-04-19 - I Built My First AI Employee (It Works 24-7).md
- Files updated: index.md, log.md
- Details: Выжимка видео Sandy Coreana о построении AI-команды для контент-автоматизации на Claude Code. Архитектура специализированных агентов (анализ, тренды, сценарии, миниатюры, монтаж, Shorts), outlier video metric, экономика $84–174/мес vs $7–8k/мес на human team, выбор Claude Code vs Claude Cowork, отказ от ChatGPT по этическим причинам, Whisper Flow, стек Google APIs + Descript + Nanobana Pro + OpenRouter

## [2026-04-19] create | YouTube Summary — 5 Anti-Cancer Habits After 50

- Source: <https://youtu.be/he0iwUMQSU0?si=ixxv9Me9NR0SMB77>
- Files created: 500_Research/530_YouTube/2026-04-19 - 5 Anti-Cancer Habits That Cut Your Risk Up To 61% After 50.md
- Files updated: index.md, log.md
- Details: Выжимка видео Dr. William Li о 5 научно обоснованных привычках, снижающих риск рака до 61% у людей старше 50: гидратация, ферментированные продукты, метаболическая ходьба, сульфорафан из крестоцветных, архитектура сна. Ссылки на исследования Harvard, Stanford, UC San Diego, мета-анализ American Cancer Society

## [2026-04-18] create | AgentOS Phase 2 PRD — co-pilot architecture

- Files created: 200_Projects/240_MicroSaaS/245_AgentOS/prd-phase-2.md
- Files updated: index.md, log.md
- Details: PRD Фазы 2 AgentOS — разделение на разговорную часть (OpenAI-compat LLM-loop, конфигурируемая модель) и исполнительную (Claude и прочие воркеры через MCP). Гибрид ack + debounce/batching, Event Bus на Redis Streams, множественные conversations per (user × agent), running summary через дешёвую модель. Build vs buy: go-sdk (MCP) + openai-go + telego + tiktoken-go. 6 этапов за 4 недели

## [2026-04-16] create | CLAUDE.md по принципам Karpathy - Threads тред

- Source: 500_Research/520_Social_Research/2026-04-13 - Google Engineer Automates 80% with Claude Code.md (Part 1)
- Files created: 300_Blog/350_Draft_Posts/351_RU/2026-04-16 CLAUDE.md по принципам Karpathy - Threads.md
- Files updated: index.md, log.md
- Details: Тред из 7 постов для Threads: CLAUDE.md по принципам Karpathy — один файл с правилами снижает ошибки ИИ с 40% до 3%, четыре принципа, 15K звёзд за неделю, ИИ может сам сгенерировать правила под проект

## [2026-04-16] ingest | Krytex Discovery Call

- Source: 000_Inbox/krytex-call-ts.md
- Destination: 200_Projects/210_AGIency/216_Clients/Krytex/Discovery Call 2026-04-16.md
- Files created: 200_Projects/210_AGIency/216_Clients/Krytex/Discovery Call 2026-04-16.md
- Files updated: index.md, log.md
- Details: Транскрипт discovery/демо-звонка с Krytex (автохимия). AI чат-бот на таблице Q&A, обсуждение расширения базы знаний, каналов (Telegram/VK/Instagram/сайт), интеграции с маркетплейсами (Ozon/WB), стоимости. Следующий шаг — КП.

## [2026-04-16] create | AgentOS PRD

- Files created: 200_Projects/240_MicroSaaS/245_AgentOS/prd.md
- Files updated: index.md, log.md
- Details: PRD для MVP AgentOS — серверная платформа оркестрации AI-агентов на Claude Code CLI (subprocess + --resume), Go Kratos + Ent + PG + NATS + Redis, Telegram-боты для управления + React-дашборд для конфигурации, модель доступа для команды

## [2026-04-16] create | ClaudeClaw The Sequel - Build Your AI Assistant

- Files created: 500_Research/530_YouTube/2026-04-16 - ClaudeClaw The Sequel - Build Your AI As....md
- Files updated: index.md, log.md
- Details: Выжимка YouTube-видео: ClaudeClaw — персональная ОС для AI-агентов на Anthropic Agent SDK, War Room (голосовой совет 5 агентов), Hive Mind (коллективная память), многослойная безопасность, PipeCat для голосового I/O

## [2026-04-16] create | OpenClaw - обзор платформы

- Files created: 500_Research/550_AI/551_Agents/OpenClaw - обзор платформы.md
- Files updated: index.md, log.md
- Details: Полный обзор OpenClaw: что это, пятислойная архитектура agent harness, возможности (браузер, система, скиллы, память, каналы), бенчмарки (79.6% с Sonnet 4.6), конкурентный ландшафт, ограничения

## [2026-04-16] create | What Is OpenClaw - The AI That Actually Does Things

- Files created: 500_Research/530_YouTube/2026-04-16 - What Is OpenClaw - The AI That Actually Does Things.md
- Files updated: index.md, log.md
- Details: Выжимка YouTube-видео: OpenClaw — self-hosted open-source AI-ассистент с навыками (Skills), заданиями (Cron Jobs), автономной работой 24/7, VPS-развёртыванием и рисками безопасности вредоносных навыков

## [2026-04-16] create | Harness важнее модели - Threads тред

- Files created: 300_Blog/350_Draft_Posts/351_RU/2026-04-16 Harness важнее модели - Threads.md
- Files updated: index.md, log.md
- Details: Тред из 7 постов для Threads: концепция harness из OpenClaw (Anthropic) применена в Clario — ИИ-ассистент РОПа перешёл от рекомендаций к замкнутому циклу контроля менеджеров

## [2026-04-16] create | Lead Magnets are Dead - MicroMagnets

- Files created: 500_Research/530_YouTube/2026-04-16 - Lead Magnets are Dead - MicroMagnets.md
- Files updated: index.md, log.md
- Details: Выжимка YouTube-видео: микро-магниты вместо традиционных лид-магнитов — матрица Hot/Safe, трёхэтапное создание (занозы → название-инструмент → чит-код), формула Leo Burnett, воронка "лёгких да"

## [2026-04-16] create | How I went PRO with content

- Files created: 500_Research/530_YouTube/2026-04-16 - How I went PRO with content.md
- Files updated: index.md, log.md
- Details: Выжимка YouTube-видео: Influential vs Influencer контент-стратегия — 3P-фреймворк (Problem/Proof/Position), цикл See-Connect-Say, продуктивность + опасность = доход

## [2026-04-16] create | How We Sign a New High-Ticket Client Every 16 Hours

- Files created: 500_Research/530_YouTube/2026-04-16 - How We Sign a New High-Ticket Client Every 16 Hours.md
- Files updated: index.md, log.md
- Details: Выжимка YouTube-видео: продажа high-ticket коучинга без sales calls — Offer Doc + Sold Out Sequence + Brandwidth контент-стратегия

## [2026-04-15] ingest | Google Engineer Automates 80% with Claude Code

- Files created: 500_Research/520_Social_Research/2026-04-13 - Google Engineer Automates 80% with Claude Code.md
- Files updated: index.md, log.md
- Details: Сохранён вирусный пост X (@noisyb0y1, ~3M просмотров): Google-инженер автоматизировал 80% работы с Claude Code, CLAUDE.md (15K звёзд), Everything Claude Code (153K звёзд), экономия $3-12K/мес

## [2026-04-13] create | Dogovor24 AI Document Estimate

- Files created: 200_Projects/230_Clario/233_PRDs/Dogovor24-AI-Document-Estimate.md
- Files updated: index.md, log.md
- Details: Оценка трудозатрат документ-ассистента — 1684 часа (Phase 1: 768ч, Phase 2: 616ч, Phase 3: 300ч), команда 4 чел. (Backend Go + AI/ML + Frontend React + DevOps)

## [2026-04-13] create | Dogovor24 AI Document Assistant PRD

- Files created: 200_Projects/230_Clario/233_PRDs/Dogovor24-AI-Document-Assistant-PRD.md
- Files updated: index.md, log.md
- Details: PRD для КП клиенту Dogovor24 — AI-ассистент по созданию юридических документов: чат-интерфейс по типу ChatGPT, графовая БД шаблонов/клауз/рисков из конструктора D24, Dialogue Agent + Graph Query Engine + Document Composer, интеграция с AI Legal Gateway (проверка рисков) и ЭДО D24 (подписание ЭЦП), стек Go Kratos + Ent

## [2026-04-12] create | Dogovor24 AI Legal Assistant PRD

- Files created: 200_Projects/230_Clario/233_PRDs/Dogovor24-AI-Legal-Assistant-PRD.md
- Files updated: index.md, log.md
- Details: PRD для КП клиенту Dogovor24 — мультиагентная AI-система юридических консультаций: Router Agent + специализированные агенты по областям права + RAG по НПА РК + интеграция с amicus-service + workflow модерации + 3-фазный переход к автоматизации

## [2026-04-09] create | Bazis Call Center Automation PRD

- Files created: 200_Projects/230_Clario/233_PRDs/Bazis-Call-Center-Automation-PRD.md
- Files updated: index.md, log.md
- Details: PRD для КП клиенту Базис — автоматизация колл-центра: голосовой ИИ-ассистент, чат-боты WhatsApp+Telegram, CRM-интеграция, гибрид Phase 1 → полная автоматизация Phase 3

## [2026-04-09] ingest | Discovery Bazis Call Center

- Source: 000_Inbox/-Orchid-lab-Bazis-3b30f7b5-bd6c.md
- Destination: 200_Projects/230_Clario/234_Chats/2026-04-08-Discovery-Bazis-Call-Center.md
- Files created: 2026-04-08-Discovery-Bazis-Call-Center.md
- Files updated: index.md, log.md
- Details: Транскрипт discovery-звонка с Никитой Сложеникиным (CMO Базис) — автоматизация колл-центра застройщика, ~200 звонков/день, запрос на единую систему голосовых и чат-ботов

## [2026-04-08] create | Wiki Infrastructure

- Files created: log.md, index.md
- Details: Инициализация LLM Wiki инфраструктуры — навигационный индекс и операционный лог

## [2026-04-08] update | CLAUDE.md — LLM Wiki workflows

- Files updated: CLAUDE.md
- Details: Добавлены index.md/log.md в структуру, workflow обновления, session start, analysis workflow, тип analysis

## [2026-04-08] create | Skills: /ingest, /wiki-lint

- Files created: .claude/skills/ingest/SKILL.md, .claude/skills/wiki-lint/SKILL.md
- Details: Два новых skill — обработка Inbox и health check хранилища

## [2026-04-08] update | Existing skills — wiki bookkeeping

- Files updated: ai-digest, daily-review, youtube-summary, social-research, web-research SKILL.md
- Details: Добавлен финальный шаг Wiki Bookkeeping (обновление index.md и log.md)

## [2026-04-08] update | Commands: inbox-processor, weekly-synthesis

- Files updated: .claude/commands/inbox-processor.md, .claude/commands/weekly-synthesis.md
- Details: inbox-processor → lightweight scan + redirect на /ingest; weekly-synthesis → lint шаг #2

## [2026-04-08] create | 590_Analysis directory

- Files created: 500_Research/590_Analysis/README.md
- Details: Новая директория для внутренне-производного анализа и синтеза

## [2026-04-08] ingest | LLM Wiki — паттерн персональной базы знаний

- Source: 000_Inbox/llm-wiki.md
- Destination: 500_Research/550_AI/LLM Wiki - паттерн персональной базы знаний.md
- Files created: 500_Research/550_AI/LLM Wiki - паттерн персональной базы знаний.md
- Files updated: index.md
- Details: Первый ingest через новый workflow. Структурированная выжимка паттерна LLM Wiki с маппингом на наш Second Brain

## [2026-04-19] query | Jensen Huang 5-layer AI cake — материал для статьи

- Files created: 500_Research/590_Analysis/Jensen Huang 5-layer AI cake - материал для статьи.md
- Files updated: index.md
- Details: Собран полный текст поста @r0ck3t23 (298k views), оригинальные цитаты Jensen Huang из NVIDIA Blog / Davos 2026 / Dwarkesh podcast, экспертные реакции (StockSavvyShay, Cassie Kozyrkov, Aakash Gupta), 6 готовых углов для статьи и ключевые цитаты ready-to-paste

## [2026-04-22] create | Вайб-кодинг лайфхак №5 — Git + лид-магнит

- Files created: 300_Blog/350_Draft_Posts/351_RU/2026-04-22 Вайб-кодинг лайфхак 5 Git.md, 300_Blog/340_Lead_Magnets/Лид-магнит - Git для вайбкодера.md
- Files updated: index.md
- Details: Тред для Threads (8 постов) + Telegram-версия про git для вайбкодеров + лид-магнит мини-гайд по git через UI VS Code (установка, коммит, откат, ветки, push на GitHub), Mac+Win

## [2026-04-25] create | Память для агентов и Ralph Loop — пост для Threads

- Files created: 300_Blog/350_Draft_Posts/351_RU/2026-04-25 Память для агентов и Ralph Loop.md
- Files updated: index.md
- Details: Драфт поста для Threads (494 символа) о том, что проблема агентов не в памяти, а в системе управления + база знаний. Включена справка про Ralph Loop (Geoffrey Huntley, 2025) и анонс собственной ОС для агентов с многосессионным выполнением задач на 1М контекста. В файле — 3 варианта хука (провокация / рефрейм / отсылка) и итоговый драфт.

## [2026-04-26] update | Память для агентов и Ralph Loop — развёрнут в тред

- Files updated: 300_Blog/350_Draft_Posts/351_RU/2026-04-25 Память для агентов и Ralph Loop.md, index.md
- Details: Single post развёрнут в тред из 4 постов со slippery slide. Пост 1 — хук+провокация (157 симв), Пост 2 — рефрейм (194), Пост 3 — Ralph Loop с механикой (237), Пост 4 — ОС для агентов + вопрос для engagement (230). Single-post версия сохранена как альтернатива.
