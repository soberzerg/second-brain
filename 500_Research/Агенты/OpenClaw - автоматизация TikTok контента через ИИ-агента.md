---
created: 2026-02-26
source: https://x.com/oliverhenry/status/2022011925903667547
author: Oliver Henry (@oliverhenry)
tags: [ai-agents, automation, tiktok, content-marketing, openclaw]
type: guide
---

# OpenClaw: автоматизация TikTok-контента через ИИ-агента

> Кейс Oliver Henry: как ИИ-агент Larry набрал 500K+ просмотров на TikTok за неделю без ручного создания контента.

## Контекст

Oliver Henry годами вручную создавал TikTok-контент для своих приложений: дизайнил изображения, писал подписи, публиковал каждый день. Работало, но медленно и неэффективно.

Решение: старый игровой ПК (NVIDIA 2070 Super) превращён в автономного ИИ-агента **Larry** на базе **OpenClaw**.

## Результаты

- **500K+ просмотров** на TikTok за 5 дней
- **MRR вырос до $714** (приложение Snugly)
- Контент конвертируется в **реальные платные подписки**
- Oliver **не дизайнил ни одного изображения** и **не писал ни одной подписи**

## Что такое OpenClaw

Open-source фреймворк персонального ИИ-ассистента, который:

- Запускается **локально** на твоём устройстве (ПК, сервер, Mac Mini)
- Подключается к мессенджерам (WhatsApp, Telegram, Slack, Discord)
- Использует **Claude (Anthropic)** как LLM-движок
- Имеет **persistent memory** — помнит контекст между сессиями
- Может **выполнять действия**: генерировать изображения, писать код, управлять браузером, публиковать контент

**Сайт:** [openclaw.ai](https://openclaw.ai/)
**GitHub:** [github.com/openclaw/openclaw](https://github.com/openclaw/openclaw)
**Discord:** [discord.gg/clawd](https://discord.gg/clawd)

## Как устроен агент Larry

### Возможности

| Компонент | Что делает |
|-----------|-----------|
| Persistent identity (SOUL.md) | Личность, стиль общения, приоритеты |
| Memory files | Логирует каждый урок, помнит что работало |
| Image generation | OpenAI API для создания изображений |
| Custom code | Сам пишет код для text overlays |
| Posting | Публикация через Postiz API |
| Skill files | Workflows для конкретных задач (например, TikTok карусели) |

### Коммуникация

Oliver общается с Larry через **WhatsApp**. Даёт задачу — Larry выполняет всё остальное автономно.

## Workflow: TikTok карусели

1. Oliver говорит Larry: "Research winning formulas for TikTok carousels"
2. Larry анализирует что работает в нише
3. Генерирует **6-slide карусели** с цепляющими хуками
4. Создаёт изображения и текстовые оверлеи
5. Публикует как **drafts** в TikTok через Postiz API
6. Oliver одобряет и публикует (или ставит на автопост)

## Quick Start: установка OpenClaw

### Требования

- ПК/сервер (Mac, Linux, Windows с WSL2) — может быть старый ПК
- Node.js 22+
- Anthropic аккаунт (Claude Pro $20/мес или Max $100-200/мес)

### Установка

```bash
# 1. Установить Node.js 22+
# Mac:
brew install node@22

# Linux:
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Установить OpenClaw
npm install -g openclaw@latest

# 3. Запустить мастер настройки (с daemon-режимом)
openclaw onboard --install-daemon
```

### Ключевые файлы конфигурации

| Файл | Назначение |
|------|-----------|
| `SOUL.md` | Личность и стиль агента |
| `AGENTS.md` | Инструкции поведения |
| `TOOLS.md` | Доступные инструменты и workflows |
| `USER.md` | Информация о тебе для контекста |
| `MEMORY.md` | Persistent memory агента |

### Подключение Telegram-канала

1. Написать @BotFather в Telegram
2. Создать бота через `/newbot`
3. Скопировать API-токен
4. Добавить токен в конфиг OpenClaw

## Ключевые принципы

1. **Start small** — начни с одного канала и одного use case
2. **Skill files** — создавай файлы-инструкции для конкретных задач (TikTok карусели, email-рассылки и т.д.)
3. **Memory system** — учи агента через memory files, он запоминает что работает
4. **Cron jobs** — автоматизируй повторяющиеся задачи (ежедневные посты, отчёты)
5. **Iterate** — агент учится на каждой итерации, улучшая результаты

## Стоимость

| Компонент | Стоимость |
|-----------|----------|
| OpenClaw | Бесплатно (open-source) |
| Claude Pro | $20/мес |
| Claude Max | $100-200/мес |
| Сервер (опционально) | $5-20/мес |
| OpenAI API (изображения) | По использованию |

## Применимость для моих проектов

### AGIents.pro
- Конкурентный анализ: OpenClaw — open-source альтернатива, AGIents — no-code enterprise
- Изучить архитектурные решения: persistent memory, skill files
- Потенциальная интеграция или вдохновение для фич

### AISobolev блог
- Отличный кейс для поста: "Как старый ПК набрал 500K просмотров на TikTok"
- Тема резонирует: автоматизация контента для соло-фаундеров
- Связь с "build in public" нарративом

### AGIency.pro
- Предложить клиентам автоматизацию TikTok/контента через агентов
- Модель: настройка OpenClaw или аналогичного агента под клиента

## Источники

- [Оригинальный пост @oliverhenry](https://x.com/oliverhenry/status/2022011925903667547)
- [Разбор на Medium (Anul Agarwal)](https://medium.com/@anulagarwal12/how-his-openclaw-agent-larry-got-millions-of-tiktok-views-in-one-week-full-step-by-step-guide-0ecb294006a5)
- [Полный гайд по установке (Dustin Fox)](https://www.foxessellfaster.com/blog/openclaw-setup-guide-how-i-built-my-own-ai-agent-complete-2026-tutorial/)
- [YouTube: ClawdBot setup](https://www.youtube.com/watch?v=BoC5MY_7aDk)
