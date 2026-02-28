---
source: https://dev.to/zackriya/local-meeting-notes-with-whisper-transcription-ollama-summaries-gemma3n-llama-mistral--2i3n
date: 2026-02-08
tags: [whisper, ollama, transcription, local-ai, architecture]
type: technical-reference
relevance: TG Claude Code Assistant voice integration
---

# Meetily: Local Meeting Notes - Whisper + Ollama Architecture

## Обзор

**Meetily** — self-hosted система для транскрибации встреч и генерации саммари полностью локально, без облачных зависимостей.

## Техническая архитектура

### Стек технологий

**Transcription Layer:**
- **Whisper** (OpenAI) — локальное преобразование аудио в текст
- Поддержка моделей: tiny, base, medium, large
- Работает без API ключей

**Summarization Layer:**
- **Ollama** — локальный LLM runtime
- Модели: Gemma 3n, LLaMA (Meta), Mistral
- Интеграция через `http://localhost:11434`

**Deployment:**
- Нативные инсталляторы: Windows, macOS (Homebrew)
- Docker поддержка: x86_64 и ARM64
- Cross-platform

### Последовательный pipeline

```
1. Audio capture (system + microphone)
   ↓
2. Local Whisper transcription
   ↓
3. Text → Ollama
   ↓
4. Summary generation + action items
   ↓
5. Local database storage
```

### Модульная архитектура

- **Frontend:** Desktop UI
- **Backend services:**
  - Whisper server: порт 8178
  - Meeting app: порт 5167
- **Storage:** SQLite (`/opt/homebrew/var/meetily/meeting_minutes.db` на macOS)

## Ключевые преимущества локальной обработки

✅ **Приватность** — данные не покидают машину
✅ **Без затрат** — нет API fees
✅ **Скорость** — нет сетевой латентности
✅ **Гибкость** — работает с любой платформой (Zoom, Teams, Discord)
✅ **Автономность** — не требует интеграций

## Применимость к TG Claude Code Assistant

### Прямые параллели

1. **Локальная обработка голоса**
   - Whisper для транскрибации голосовых сообщений в Telegram
   - Ollama как альтернатива Claude API для базовых задач

2. **Offline-first архитектура**
   - SQLite для хранения истории
   - Работа без постоянного подключения к облаку

3. **Модульность**
   - Разделение: Telegram Bot ↔ Whisper Service ↔ Claude CLI
   - Whisper на порту 8178 (как в Meetily)

### Отличия от нашего подхода

| Meetily | TG Claude Code Assistant |
|---------|--------------------------|
| Ollama (локальные модели) | Claude API (облачная модель) |
| Desktop app | Telegram bot |
| Конференции (длинные аудио) | Голосовые сообщения (короткие) |
| Саммари встреч | Общие AI-задачи |

### Что можно перенять

1. **Whisper интеграция:**
   ```python
   # Встроенный Whisper сервер на порту 8178
   whisper_url = "http://localhost:8178/transcribe"
   ```

2. **Локальное хранение:**
   ```sql
   -- SQLite для истории транскрипций
   CREATE TABLE transcriptions (
       id INTEGER PRIMARY KEY,
       telegram_user_id INTEGER,
       audio_path TEXT,
       transcription TEXT,
       timestamp DATETIME
   );
   ```

3. **Модульная архитектура:**
   ```
   tg-bot → whisper-service → claude-cli → response
              ↓
           sqlite (history)
   ```

## Технические детали установки

### macOS (Homebrew)
```bash
brew tap zackriya/meetily
brew install meetily
# Auto migration: /opt/homebrew/var/meetily/meeting_minutes.db
```

### Docker
```bash
# Поддержка x86_64 и ARM64
docker build -t meetily .
docker run -p 8178:8178 -p 5167:5167 meetily
```

## Конфигурация

**Ollama настройка:**
- Base URL: `http://localhost:11434`
- Выбор модели: Settings → LLM Provider
- Language preference: Settings → Language

**Whisper настройка:**
- Выбор модели (tiny/base/medium/large)
- Аудио источники: system + microphone

## Выводы для проекта

### ✅ Что подходит для TG bot:
- Whisper для голосовых сообщений
- SQLite для истории
- Модульная архитектура сервисов

### ❌ Что НЕ подходит:
- Ollama вместо Claude (у нас другая задача — полноценный AI-агент)
- Desktop UI (у нас Telegram)
- Длинные встречи (у нас короткие голосовые)

### 🎯 Следующие шаги:
1. Изучить Whisper Python API для интеграции
2. Спроектировать whisper-service как отдельный компонент
3. Реализовать SQLite схему для хранения транскрипций
4. Интегрировать в существующий masterplan

---

## Связанные материалы

- `TG Claude Code Assistant/masterplan.md` — основной план проекта
- Whisper official docs — https://github.com/openai/whisper
- Ollama docs — https://ollama.ai/

*Добавлено: 2026-02-10*
