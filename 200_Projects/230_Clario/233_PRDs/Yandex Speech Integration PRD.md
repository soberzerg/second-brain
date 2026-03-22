---
type: project-doc
date: 2026-03-18
project: Clario
status: draft
tags: [transcription, yandex-speech, stt, prd]
---

# Clario — Yandex.Speech Integration PRD

## Контекст

Этот PRD детализирует интеграцию Yandex Speech Kit (STT v3) в Clario Transcription Service. Основан на рабочем прототипе из проекта SorokinFit (n8n workflow `Denis Sorokin Fitness Bot - Incoming`), где Yandex STT v3 Async API успешно транскрибирует голосовые сообщения Telegram.

Является дополнением к [[Meeting Transcription PRD]] — описывает конкретную реализацию транскрибации через Yandex.Speech.

## Референсная реализация (SorokinFit)

### Архитектура потока в n8n

```
Telegram Voice → Get File (.ogg) → Upload S3 → Yandex STT Start (Async)
    → Wait → Get Result (файл NDJSON) → Parse → Extract Text → Send to Agent
```

### Ключевые решения в прототипе

| Аспект | Реализация | Комментарий |
|--------|-----------|-------------|
| **API** | STT v3 Async (`recognizeFileAsync`) | Асинхронный — подходит для длинных записей |
| **Эндпоинт** | `stt.api.ml.yandexcloud.kz` | Казахстанский регион (ближе к Clario-клиентам) |
| **Аудио-формат** | OGG_OPUS (нативный Telegram) | Не требует конвертации |
| **Модель** | `general` | Универсальная, работает для разговорной речи |
| **Язык** | `ru-RU` (whitelist) | Только русский, без автодетекции |
| **Нормализация** | `TEXT_NORMALIZATION_ENABLED` | Числа, даты, сокращения в читаемом виде |
| **Хранилище** | Yandex Object Storage (S3-compatible) | Файл доступен по публичному URL |
| **Аутентификация** | API Key через HTTP Header | Простой вариант |
| **Формат результата** | NDJSON (multiline JSON) | Каждая строка — JSON с partial/final результатом |
| **Извлечение текста** | `finalRefinement.normalizedText.alternatives[0].text` с fallback на `final.alternatives[0].text` | Два уровня: refined и базовый |

### API-контракт (из прототипа)

**Запуск распознавания:**
```json
POST https://stt.api.ml.yandexcloud.kz/stt/v3/recognizeFileAsync
Authorization: Api-Key <API_KEY>

{
  "uri": "https://storage.yandexcloud.kz/bucket/path/file.ogg",
  "recognitionModel": {
    "model": "general",
    "audioFormat": {
      "containerAudio": {
        "containerAudioType": "OGG_OPUS"
      }
    },
    "textNormalization": {
      "textNormalization": "TEXT_NORMALIZATION_ENABLED"
    },
    "languageRestriction": {
      "restrictionType": "WHITELIST",
      "languageCode": ["ru-RU"]
    }
  }
}

Response: { "id": "<operation_id>", ... }
```

**Получение результата:**
```
GET https://stt.api.ml.yandexcloud.kz/stt/v3/getRecognition?operationId=<id>
Authorization: Api-Key <API_KEY>

Response: NDJSON файл (строки JSON)
```

**Структура результата (NDJSON):**
```json
{"result": {"finalRefinement": {"normalizedText": {"alternatives": [{"text": "распознанный текст"}]}}}}
{"result": {"final": {"alternatives": [{"text": "текст без нормализации"}]}}}
```

## Архитектура для Clario

### Отличия от прототипа

| Аспект | SorokinFit (прототип) | Clario (продакшен) |
|--------|----------------------|-------------------|
| **Источник аудио** | Telegram voice (короткие, <1 мин) | Google Meet записи (30-90 мин) |
| **Формат** | OGG_OPUS | WAV/MP3 (из Recall.ai) |
| **Языки** | Только ru-RU | ru-RU + kk-KK (казахский) |
| **Speaker diarization** | Не нужен (1 спикер) | Обязателен (2+ спикера) |
| **Обработка ошибок** | Нет retry | Retry + DLQ + алерты |
| **Масштаб** | Единичные сообщения | 50-100 звонков/день |
| **Ожидание результата** | Простой Wait (фиксированная пауза) | Polling с exponential backoff |

### Компоненты

```
                    ┌──────────────────────────┐
                    │   Transcription Service   │
                    │       (Go/Kratos)         │
                    └──────────┬───────────────┘
                               │ NATS: audio.ready
                               ▼
┌────────────────────────────────────────────────────────────┐
│              AI Processing Service (Python/FastAPI)         │
│                                                             │
│  ┌──────────────────┐    ┌─────────────────────────────┐   │
│  │  Provider Router  │───▶│  YandexSpeechProvider       │   │
│  │                   │    │                              │   │
│  │  - language       │    │  1. Upload audio to S3       │   │
│  │  - audio format   │    │  2. POST recognizeFileAsync  │   │
│  │  - fallback logic │    │  3. Poll getRecognition      │   │
│  │                   │    │  4. Parse NDJSON response    │   │
│  │                   │    │  5. Return TranscriptResult  │   │
│  └──────────────────┘    └─────────────────────────────┘   │
│           │                                                 │
│           │              ┌─────────────────────────────┐   │
│           └─────────────▶│  ElevenLabsProvider          │   │
│                          │  (основной для ru-RU)        │   │
│                          └─────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

### Provider Interface

```python
class TranscriptResult:
    segments: list[TranscriptSegment]  # реплики с тайм-кодами
    full_text: str                      # полный текст
    language: str                       # определённый язык
    provider: str                       # "yandex" | "elevenlabs"
    duration_ms: int                    # длительность аудио
    confidence: float                   # средняя уверенность

class TranscriptSegment:
    speaker_id: int
    text: str
    start_ms: int
    end_ms: int
    confidence: float

class TranscriptionProvider(Protocol):
    async def transcribe(
        self,
        audio_url: str,
        audio_format: AudioFormat,
        language: str,
        options: TranscriptionOptions,
    ) -> TranscriptResult: ...
```

### YandexSpeechProvider — детальная логика

```python
class YandexSpeechProvider:
    """
    Реализация на основе рабочего прототипа SorokinFit.
    API: Yandex STT v3 Async (recognizeFileAsync).
    """

    BASE_URL = "https://stt.api.ml.yandexcloud.kz/stt/v3"

    async def transcribe(self, audio_url, audio_format, language, options):
        # 1. Запуск асинхронного распознавания
        operation_id = await self._start_recognition(
            uri=audio_url,
            audio_format=audio_format,
            language=language,
        )

        # 2. Polling результата с exponential backoff
        # Прототип использует фиксированный Wait — для длинных записей нужен polling
        result_ndjson = await self._poll_result(
            operation_id=operation_id,
            initial_delay=5,      # секунд
            max_delay=30,         # секунд
            timeout=600,          # 10 мин макс
        )

        # 3. Парсинг NDJSON (логика из прототипа extract-stt-text)
        segments = self._parse_ndjson(result_ndjson)

        return TranscriptResult(segments=segments, ...)

    def _parse_ndjson(self, ndjson_text: str) -> list[TranscriptSegment]:
        """
        Адаптировано из SorokinFit Code-ноды:
        - Каждая строка — JSON
        - Ищем finalRefinement.normalizedText.alternatives[0].text
        - Fallback: final.alternatives[0].text
        """
        segments = []
        for line in ndjson_text.strip().split("\n"):
            data = json.loads(line).get("result", {})

            text = ""
            if fr := data.get("finalRefinement"):
                text = (
                    fr.get("normalizedText", {})
                    .get("alternatives", [{}])[0]
                    .get("text", "")
                )
            elif f := data.get("final"):
                text = f.get("alternatives", [{}])[0].get("text", "")

            if text:
                segments.append(TranscriptSegment(text=text, ...))

        return segments
```

### Routing-логика (выбор провайдера)

| Язык | Основной провайдер | Fallback | Обоснование |
|------|-------------------|----------|-------------|
| `ru-RU` | ElevenLabs | Yandex Speech | ElevenLabs лучше качество для русского |
| `kk-KK` | Yandex Speech | — | Единственный провайдер с казахским |
| `auto` | ElevenLabs (language detect) | Yandex Speech | Авто-определение языка |

### Конвертация аудио

Recall.ai отдаёт WAV/MP3. Yandex STT поддерживает:
- `OGG_OPUS` (прототип SorokinFit)
- `MP3`
- `WAV` (LINEAR16_PCM)

**Решение:** передавать WAV напрямую без конвертации (формат `RAW_AUDIO` с `LINEAR16_PCM`), либо MP3 если Recall.ai отдаёт MP3.

### Speaker Diarization

Yandex STT v3 поддерживает speaker diarization через параметр `speakerLabeling`:

```json
{
  "recognitionModel": {
    "model": "general",
    "audioFormat": { ... },
    "speakerLabeling": {
      "speakerLabeling": "SPEAKER_LABELING_ENABLED"
    }
  }
}
```

В прототипе SorokinFit не используется (1 спикер). Для Clario — обязательно.

## Конфигурация и секреты

### Переменные окружения

```env
# Yandex Speech Kit
YANDEX_STT_API_KEY=<api-key>
YANDEX_STT_BASE_URL=https://stt.api.ml.yandexcloud.kz/stt/v3

# S3 для аудио (Yandex Object Storage)
YANDEX_S3_ENDPOINT=https://storage.yandexcloud.kz
YANDEX_S3_BUCKET=clario-audio
YANDEX_S3_ACCESS_KEY=<access-key>
YANDEX_S3_SECRET_KEY=<secret-key>
YANDEX_S3_REGION=kz1
```

### Аутентификация

Прототип использует `Api-Key` через HTTP Header Auth. Для продакшена:
- **Вариант 1:** API Key (как в прототипе) — проще, подходит для MVP
- **Вариант 2:** IAM Token (OAuth) — более безопасно, автоматическая ротация

**Рекомендация MVP:** API Key, мигрировать на IAM Token в Phase 2.

## Обработка ошибок

### Стратегия retry

```
Yandex STT Start → (ошибка 429/5xx) → retry 3 раза с exponential backoff
Yandex STT Get Result → (ошибка/не готово) → poll каждые N сек до timeout
Timeout (10 мин) → пометить как FAILED → отправить в DLQ → алерт
```

### Возможные ошибки

| Ошибка | Действие |
|--------|----------|
| 400 Bad Request | Логировать, не retry. Проверить формат аудио |
| 401 Unauthorized | Алерт. Проверить API Key |
| 429 Too Many Requests | Retry с backoff. Рассмотреть rate limit |
| 500 Internal Server Error | Retry 3 раза |
| Timeout (операция > 10 мин) | Пометить FAILED, алерт |
| Пустой результат | Fallback на альтернативный провайдер |

## Стоимость

### Yandex Speech Kit pricing (STT)

- **Async API:** ~0.16 ₽ за 15 секунд аудио
- **1 час аудио:** ~38.4 ₽ (~$0.40)
- **При 100 звонках/день по 45 мин:** ~2,880 ₽/день (~$30/день, ~$900/мес)

### Сравнение

| Провайдер | Стоимость за 1 час | Качество ru-RU | Качество kk-KK |
|-----------|--------------------|----------------|-----------------|
| Yandex STT | ~$0.40 | Высокое | Высокое |
| ElevenLabs | ~$0.50 | Высокое | Нет |
| OpenAI Whisper API | ~$0.36 | Среднее | Низкое |
| Google Speech-to-Text | ~$0.96 | Среднее | Нет |

## Этапы реализации

### Этап 1: Базовая интеграция (1 неделя)

- [ ] Создать `YandexSpeechProvider` по интерфейсу `TranscriptionProvider`
- [ ] Реализовать `recognizeFileAsync` + polling (адаптация из прототипа)
- [ ] Реализовать парсинг NDJSON-ответа (перенос логики из SorokinFit)
- [ ] Интеграционные тесты с реальным API
- [ ] Настроить S3-бакет `clario-audio` в Yandex Cloud

### Этап 2: Speaker Diarization + языки (1 неделя)

- [ ] Включить `speakerLabeling` в запросе
- [ ] Маппинг speaker labels на `TranscriptSegment.speaker_id`
- [ ] Добавить поддержку `kk-KK` (казахский)
- [ ] Тестирование на реальных записях встреч (30-60 мин)

### Этап 3: Routing + Fallback (3-5 дней)

- [ ] Реализовать `ProviderRouter` с логикой выбора провайдера
- [ ] Fallback: если ElevenLabs → ошибка → Yandex
- [ ] Метрики: время обработки, WER, стоимость по провайдерам

### Этап 4: Продакшен-hardening (1 неделя)

- [ ] Retry с exponential backoff
- [ ] DLQ для failed transcriptions
- [ ] Мониторинг: Prometheus метрики (latency, error rate, cost)
- [ ] Алерты при массовых ошибках
- [ ] Rate limiting (квоты Yandex API)

## Критерии приёмки

- [ ] Голосовое сообщение Telegram (OGG_OPUS) транскрибируется через Yandex STT ≤30 секунд
- [ ] Запись Google Meet (WAV, 45 мин) транскрибируется ≤10 минут
- [ ] Speaker diarization корректно разделяет 2+ спикеров в ≥80% случаев
- [ ] Казахский язык (`kk-KK`) распознаётся с WER <15%
- [ ] Fallback на Yandex срабатывает при ошибке ElevenLabs
- [ ] Retry корректно обрабатывает 429/5xx ошибки
- [ ] Стоимость обработки не превышает $0.50/час аудио

---

## Связанные документы

- [[Meeting Transcription PRD]] — общий PRD транскрибации для Clario
- [[Clario Data Architecture Vision]] — архитектура данных Clario
- [[Clario v2 RoadMap]] — дорожная карта продукта
