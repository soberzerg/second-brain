# API Channel Integration Guide

Руководство по интеграции с каналом **API** — универсальным способом подключения внешних систем к платформе AGIents через HTTP webhooks.

## Содержание

1. [Обзор](#обзор)
2. [Архитектура](#архитектура)
3. [Настройка канала](#настройка-канала)
4. [Входящие сообщения (Incoming)](#входящие-сообщения-incoming)
5. [Исходящие сообщения (Outgoing)](#исходящие-сообщения-outgoing)
6. [Аутентификация](#аутентификация)
7. [Примеры интеграций](#примеры-интеграций)
8. [Обработка ошибок](#обработка-ошибок)
9. [Best Practices](#best-practices)

---

## Обзор

Канал **API** позволяет интегрировать любую внешнюю систему с AI-агентами AGIents через стандартные HTTP webhooks. Это универсальное решение для:

- Интеграции с no-code платформами (n8n, Make, Zapier)
- Подключения кастомных мессенджеров и чат-виджетов
- Создания API-first интеграций
- Построения middleware между AGIents и внешними системами

### Ключевые особенности

| Характеристика | Описание |
|----------------|----------|
| Протокол | HTTP/HTTPS (JSON) |
| Входящие | POST webhook на endpoint AGIents |
| Исходящие | POST webhook на ваш endpoint |
| Аутентификация | API Key, Bearer Token, или без аутентификации |
| Идемпотентность | Поддержка через `message_id` |
| Вложения | URL-based attachments |

---

## Архитектура

```
┌─────────────────┐                    ┌─────────────────┐                    ┌─────────────────┐
│                 │                    │                 │                    │                 │
│  Your System    │   1. Incoming      │   Messengers    │   2. Agent Run     │     Agents      │
│  (n8n, Make,    │───────────────────>│    Service      │───────────────────>│     Service     │
│   Custom App)   │                    │                 │                    │                 │
│                 │<───────────────────│                 │<───────────────────│                 │
│                 │   4. Outgoing      │                 │   3. Final Result  │                 │
└─────────────────┘      Webhook       └─────────────────┘                    └─────────────────┘
```

### Поток данных

1. **Incoming**: Ваша система отправляет POST-запрос на webhook endpoint AGIents
2. **Agent Run**: Messengers создаёт/обновляет чат и запускает AI-агента
3. **Final Result**: Агент завершает работу и возвращает результат
4. **Outgoing**: Messengers отправляет результат на ваш webhook endpoint

---

## Настройка канала

### Создание конфигурации канала

```http
POST /v1/messengers/channel-configs
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "project_id": 123,
  "channel": "api",
  "name": "My API Integration",
  "default_agent_id": 456,
  "credentials": {
    "webhook_url": "https://your-system.com/webhook/incoming",
    "auth_type": "api_key",
    "api_key": "your-secret-key",
    "api_key_header": "X-API-Key"
  },
  "settings": {
    "webhook_timeout": 30,
    "retry_attempts": 3,
    "retry_delay": 5,
    "include_history": true,
    "max_history_messages": 10
  }
}
```

### Поля credentials

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| `webhook_url` | string | **Да** | URL для отправки исходящих сообщений (ответов агента) |
| `auth_type` | string | Нет | Тип аутентификации: `none`, `api_key`, `bearer` |
| `api_key` | string | Для `api_key` | API ключ для аутентификации |
| `api_key_header` | string | Нет | Имя заголовка для API ключа (по умолчанию: `X-API-Key`) |
| `bearer_token` | string | Для `bearer` | Bearer токен для аутентификации |

### Поля settings

| Поле | Тип | По умолчанию | Описание |
|------|-----|--------------|----------|
| `webhook_timeout` | int | 30 | Таймаут запроса в секундах |
| `retry_attempts` | int | 3 | Количество попыток при ошибке |
| `retry_delay` | int | 5 | Задержка между попытками в секундах |
| `include_history` | bool | false | Включать историю диалога в исходящий webhook |
| `max_history_messages` | int | 10 | Максимум сообщений в истории |

### Ответ при создании

```json
{
  "channel_config": {
    "id": 789,
    "tenant_id": 1,
    "project_id": 123,
    "channel": "api",
    "name": "My API Integration",
    "is_active": true,
    "webhook_url": "https://api.agients.ru/v1/messengers/webhook/api/abc123secret",
    "default_agent_id": 456,
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z"
  }
}
```

**Важно**: Сохраните `webhook_url` из ответа — это endpoint для входящих сообщений.

---

## Входящие сообщения (Incoming)

### Endpoint

```
POST /v1/messengers/webhook/api/{webhook_secret}
```

`webhook_secret` — уникальный идентификатор канала, получаемый при создании конфигурации.

### Формат запроса

```http
POST /v1/messengers/webhook/api/abc123secret
Content-Type: application/json

{
  "message_id": "ext-msg-001",
  "chat_id": "conversation-123",
  "user_id": "user-456",
  "content": "Привет! Помоги мне с заказом.",
  "user_name": "Иван Петров",
  "user_avatar_url": "https://example.com/avatar.jpg",
  "attachments": [
    {
      "type": "photo",
      "url": "https://example.com/image.jpg",
      "file_name": "screenshot.jpg",
      "mime_type": "image/jpeg",
      "size": 102400
    }
  ],
  "metadata": {
    "source": "mobile_app",
    "order_id": "ORD-789"
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Описание полей запроса

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| `message_id` | string | Нет | Уникальный ID сообщения для идемпотентности. Если не указан — генерируется автоматически |
| `chat_id` | string | **Да** | Внешний идентификатор чата/диалога |
| `user_id` | string | **Да** | Внешний идентификатор пользователя |
| `content` | string | **Да** | Текст сообщения |
| `user_name` | string | Нет | Отображаемое имя пользователя |
| `user_avatar_url` | string | Нет | URL аватара пользователя |
| `attachments` | array | Нет | Список вложений |
| `metadata` | object | Нет | Произвольные метаданные (передаются агенту) |
| `timestamp` | string | Нет | Время сообщения в формате RFC3339 |

### Формат вложений (attachments)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| `type` | string | **Да** | Тип: `photo`, `document`, `audio`, `video` |
| `url` | string | **Да** | Прямая ссылка на файл |
| `file_name` | string | Нет | Оригинальное имя файла |
| `mime_type` | string | Нет | MIME-тип файла |
| `size` | int64 | Нет | Размер файла в байтах |

### Формат ответа (успех)

```json
{
  "status": "ok",
  "message_id": "550e8400-e29b-41d4-a716-446655440000",
  "chat_id": 12345
}
```

| Поле | Описание |
|------|----------|
| `status` | Статус обработки: `ok` или `error` |
| `message_id` | Внутренний UUID сообщения в системе |
| `chat_id` | Внутренний ID чата в системе |

### Формат ответа (ошибка)

```json
{
  "status": "error",
  "message_id": "",
  "chat_id": 0,
  "error": "channel config not found"
}
```

### HTTP статусы

| Код | Описание |
|-----|----------|
| 200 | Сообщение успешно обработано |
| 400 | Невалидный запрос (отсутствуют обязательные поля) |
| 404 | Конфигурация канала не найдена |
| 500 | Внутренняя ошибка сервера |

---

## Исходящие сообщения (Outgoing)

Когда AI-агент завершает обработку, messengers отправляет POST-запрос на ваш `webhook_url`.

### Формат исходящего webhook

```http
POST https://your-system.com/webhook/incoming
Content-Type: application/json
X-API-Key: your-secret-key
User-Agent: Messengers-Service/1.0

{
  "event": "message",
  "timestamp": "2024-01-15T10:31:05Z",
  "chat": {
    "id": 12345,
    "external_chat_id": "conversation-123",
    "external_user_id": "user-456",
    "user_name": "Иван Петров"
  },
  "message": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "content": "Здравствуйте! Я нашёл ваш заказ ORD-789. Статус: в обработке. Ожидаемая дата доставки: 20 января.",
    "agent_run_id": "770e8400-e29b-41d4-a716-446655440002"
  },
  "history": [
    {
      "role": "user",
      "content": "Привет! Помоги мне с заказом.",
      "timestamp": "2024-01-15T10:30:00Z"
    },
    {
      "role": "assistant",
      "content": "Здравствуйте! Я нашёл ваш заказ ORD-789...",
      "timestamp": "2024-01-15T10:31:05Z"
    }
  ],
  "metadata": {
    "chat_id": 12345,
    "external_chat_id": "conversation-123",
    "external_user_id": "user-456",
    "message_id": "ext-msg-001",
    "channel": "api"
  }
}
```

### Описание полей исходящего webhook

#### Корневой уровень

| Поле | Тип | Описание |
|------|-----|----------|
| `event` | string | Тип события, всегда `"message"` |
| `timestamp` | string | Время отправки в формате RFC3339 |
| `chat` | object | Информация о чате |
| `message` | object | Содержимое сообщения агента |
| `history` | array | История диалога (если включена в settings) |
| `metadata` | object | Метаданные из запроса агента |

#### Объект chat

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | int64 | Внутренний ID чата |
| `external_chat_id` | string | Внешний идентификатор чата (ваш) |
| `external_user_id` | string | Внешний идентификатор пользователя (ваш) |
| `user_name` | string | Имя пользователя |

#### Объект message

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | string | UUID сообщения в системе |
| `content` | string | Текст ответа агента |
| `agent_run_id` | string | UUID запуска агента |

#### Объект history (если включён)

| Поле | Тип | Описание |
|------|-----|----------|
| `role` | string | Роль: `user` или `assistant` |
| `content` | string | Текст сообщения |
| `timestamp` | string | Время сообщения в формате RFC3339 |

### Ожидаемый ответ от вашего webhook

Messengers ожидает HTTP статус `2xx` для подтверждения успешной доставки.

```json
{
  "status": "ok"
}
```

**Важно**: Если ваш webhook возвращает ошибку (4xx, 5xx), messengers будет повторять попытки согласно настройкам `retry_attempts` и `retry_delay`.

---

## Аутентификация

### Входящие запросы (к AGIents)

Аутентификация происходит через `webhook_secret` в URL. Убедитесь, что секрет хранится безопасно и не передаётся третьим лицам.

### Исходящие запросы (от AGIents)

Поддерживаются три метода аутентификации:

#### 1. Без аутентификации (`auth_type: "none"`)

```json
{
  "credentials": {
    "webhook_url": "https://your-system.com/webhook",
    "auth_type": "none"
  }
}
```

#### 2. API Key (`auth_type: "api_key"`)

```json
{
  "credentials": {
    "webhook_url": "https://your-system.com/webhook",
    "auth_type": "api_key",
    "api_key": "your-secret-api-key",
    "api_key_header": "X-API-Key"
  }
}
```

Заголовок запроса:
```
X-API-Key: your-secret-api-key
```

#### 3. Bearer Token (`auth_type: "bearer"`)

```json
{
  "credentials": {
    "webhook_url": "https://your-system.com/webhook",
    "auth_type": "bearer",
    "bearer_token": "your-bearer-token"
  }
}
```

Заголовок запроса:
```
Authorization: Bearer your-bearer-token
```

---

## Примеры интеграций

### n8n Workflow

#### Входящий webhook (n8n → AGIents)

1. Создайте HTTP Request node в n8n
2. Настройте:
   - Method: POST
   - URL: `https://api.agients.ru/v1/messengers/webhook/api/{webhook_secret}`
   - Body Content Type: JSON
   - Body:
   ```json
   {
     "chat_id": "{{ $json.conversation_id }}",
     "user_id": "{{ $json.sender_id }}",
     "content": "{{ $json.message }}",
     "user_name": "{{ $json.sender_name }}"
   }
   ```

#### Исходящий webhook (AGIents → n8n)

1. Создайте Webhook node в n8n
2. Скопируйте URL webhook и укажите в `credentials.webhook_url` при создании канала
3. Обработайте входящие данные:
   ```javascript
   // В Function node
   const response = $input.all()[0].json;
   return {
     chatId: response.chat.external_chat_id,
     userId: response.chat.external_user_id,
     agentResponse: response.message.content
   };
   ```

### Make (Integromat) Scenario

#### Входящий модуль

Используйте модуль **HTTP > Make a request**:
- URL: `https://api.agients.ru/v1/messengers/webhook/api/{webhook_secret}`
- Method: POST
- Body type: Raw
- Content type: JSON

#### Исходящий модуль

1. Создайте **Webhooks > Custom webhook**
2. Укажите URL в настройках канала

### cURL примеры

#### Отправка сообщения

```bash
curl -X POST "https://api.agients.ru/v1/messengers/webhook/api/abc123secret" \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "chat-001",
    "user_id": "user-001",
    "content": "Расскажи о погоде в Москве",
    "user_name": "Тестовый пользователь"
  }'
```

#### Ответ

```json
{
  "status": "ok",
  "message_id": "550e8400-e29b-41d4-a716-446655440000",
  "chat_id": 12345
}
```

### Python пример

```python
import requests
import json

WEBHOOK_URL = "https://api.agients.ru/v1/messengers/webhook/api/abc123secret"

def send_message(chat_id: str, user_id: str, content: str, user_name: str = None):
    payload = {
        "chat_id": chat_id,
        "user_id": user_id,
        "content": content
    }
    if user_name:
        payload["user_name"] = user_name

    response = requests.post(
        WEBHOOK_URL,
        headers={"Content-Type": "application/json"},
        data=json.dumps(payload)
    )

    return response.json()

# Использование
result = send_message(
    chat_id="conv-123",
    user_id="user-456",
    content="Привет! Как дела?",
    user_name="Иван"
)
print(f"Message ID: {result['message_id']}, Chat ID: {result['chat_id']}")
```

### Node.js пример

```javascript
const axios = require('axios');

const WEBHOOK_URL = 'https://api.agients.ru/v1/messengers/webhook/api/abc123secret';

async function sendMessage(chatId, userId, content, userName = null) {
  const payload = {
    chat_id: chatId,
    user_id: userId,
    content: content
  };

  if (userName) {
    payload.user_name = userName;
  }

  const response = await axios.post(WEBHOOK_URL, payload, {
    headers: { 'Content-Type': 'application/json' }
  });

  return response.data;
}

// Использование
sendMessage('conv-123', 'user-456', 'Привет!', 'Иван')
  .then(result => console.log(`Message ID: ${result.message_id}`))
  .catch(err => console.error(err));
```

### Обработчик исходящего webhook (Python/Flask)

```python
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/webhook/incoming', methods=['POST'])
def handle_webhook():
    data = request.json

    # Извлекаем данные
    chat_id = data['chat']['external_chat_id']
    user_id = data['chat']['external_user_id']
    agent_response = data['message']['content']

    # Обрабатываем ответ агента (например, отправляем в ваш чат)
    print(f"Chat {chat_id}: Agent says: {agent_response}")

    # Сохраняем в БД, отправляем уведомление и т.д.

    return jsonify({"status": "ok"}), 200

if __name__ == '__main__':
    app.run(port=5000)
```

---

## Обработка ошибок

### Коды ошибок входящего webhook

| Код | Reason | Описание |
|-----|--------|----------|
| 404 | `CHANNEL_NOT_CONFIGURED` | Канал с указанным webhook_secret не найден |
| 400 | `INVALID_REQUEST` | Невалидный формат запроса |
| 400 | `VALIDATION` | Отсутствуют обязательные поля |
| 500 | `DATABASE_QUERY` | Ошибка базы данных |

### Retry логика исходящего webhook

При ошибке доставки messengers повторяет попытки:

1. **Первая попытка** — немедленно
2. **Повторные попытки** — с задержкой `retry_delay` секунд
3. **Максимум попыток** — `retry_attempts`

**Важно**: Retry НЕ выполняется для клиентских ошибок (HTTP 4xx), только для серверных (5xx) и сетевых ошибок.

### Идемпотентность

Для предотвращения дублирования сообщений используйте уникальный `message_id`:

```json
{
  "message_id": "unique-id-12345",
  "chat_id": "conv-123",
  "user_id": "user-456",
  "content": "Текст сообщения"
}
```

Если сообщение с таким `message_id` уже обработано, повторный запрос вернёт существующие данные без создания дубликата.

---

## Best Practices

### Безопасность

1. **Храните webhook_secret безопасно** — не включайте в клиентский код
2. **Используйте HTTPS** — для webhook_url используйте только защищённые соединения
3. **Валидируйте входящие запросы** — проверяйте аутентификацию на вашем webhook endpoint
4. **Ротируйте секреты** — периодически обновляйте API ключи и токены

### Производительность

1. **Отвечайте быстро** — webhook endpoint должен отвечать в течение `webhook_timeout` секунд
2. **Обрабатывайте асинхронно** — если обработка долгая, возвращайте 200 OK сразу и обрабатывайте в фоне
3. **Используйте идемпотентность** — всегда передавайте `message_id` для предотвращения дубликатов

### Мониторинг

1. **Логируйте запросы** — сохраняйте логи входящих и исходящих webhook для отладки
2. **Отслеживайте ошибки** — настройте алерты на частые ошибки доставки
3. **Проверяйте статусы** — используйте внутренний `chat_id` и `message_id` для отслеживания

### Тестирование

1. **Используйте тестовый webhook** — инструменты типа webhook.site для отладки исходящих запросов
2. **Проверяйте retry** — убедитесь, что ваш webhook корректно обрабатывает повторные запросы
3. **Тестируйте таймауты** — проверьте поведение при медленных ответах

---

## Диаграмма последовательности

```
┌──────────────┐          ┌──────────────┐          ┌──────────────┐          ┌──────────────┐
│  Your App    │          │  Messengers  │          │   Agents     │          │  Your Webhook│
└──────┬───────┘          └──────┬───────┘          └──────┬───────┘          └──────┬───────┘
       │                         │                         │                         │
       │  1. POST /webhook/api   │                         │                         │
       │  {chat_id, user_id,     │                         │                         │
       │   content}              │                         │                         │
       │────────────────────────>│                         │                         │
       │                         │                         │                         │
       │                         │  2. Get/Create Chat     │                         │
       │                         │  3. Create Message      │                         │
       │                         │                         │                         │
       │                         │  4. NATS: agent_run_    │                         │
       │                         │     start               │                         │
       │                         │────────────────────────>│                         │
       │                         │                         │                         │
       │  5. Response            │                         │                         │
       │  {status: ok,           │                         │                         │
       │   message_id, chat_id}  │                         │                         │
       │<────────────────────────│                         │                         │
       │                         │                         │                         │
       │                         │                         │  6. Run Agent (LLM)    │
       │                         │                         │                         │
       │                         │  7. NATS: channel_api   │                         │
       │                         │  {final_result}         │                         │
       │                         │<────────────────────────│                         │
       │                         │                         │                         │
       │                         │  8. POST webhook_url    │                         │
       │                         │  {event, chat, message} │                         │
       │                         │────────────────────────────────────────────────────>│
       │                         │                         │                         │
       │                         │  9. Response 200 OK     │                         │
       │                         │<────────────────────────────────────────────────────│
       │                         │                         │                         │
```

---

## Примечания

- Канал API идеально подходит для интеграции с middleware-платформами
- Для высоконагруженных интеграций рассмотрите использование прямого gRPC подключения
- История чата сохраняется и передаётся агенту для контекста диалога
- Метаданные из входящего сообщения передаются агенту и возвращаются в исходящем webhook
