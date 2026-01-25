# Руководство по интеграции Telegram Bot API для AGIents

**Версия:** 1.0
**Дата:** 22 января 2026
**Автор:** AGIents.pro
**Целевая аудитория:** Разработчики, интегрирующие ИИ-ботов в Telegram

---

## Оглавление

1. [Обзор Telegram Bot API](#1-обзор-telegram-bot-api)
2. [Архитектура интеграции](#2-архитектура-интеграции)
3. [Создание и настройка бота](#3-создание-и-настройка-бота)
4. [Получение событий: Webhook vs Long Polling](#4-получение-событий-webhook-vs-long-polling)
5. [Работа с сообщениями](#5-работа-с-сообщениями)
6. [Клавиатура бота](#6-клавиатура-бота)
7. [Обработка событий](#7-обработка-событий)
8. [Безопасность](#8-безопасность)
9. [Примеры реализации](#9-примеры-реализации)
10. [Рекомендации для стоматологий](#10-рекомендации-для-стоматологий)
11. [Ссылки на документацию](#11-ссылки-на-документацию)

---

## 1. Обзор Telegram Bot API

### Что такое Telegram Bot

**Бот** — специальный аккаунт Telegram, управляемый программно через HTTP API. Боты могут отвечать на сообщения, отправлять уведомления, принимать платежи и интегрироваться с внешними сервисами.

### Преимущества платформы Telegram

| Преимущество | Описание |
|--------------|----------|
| **Скорость** | Мгновенная доставка сообщений, быстрый API |
| **Безопасность** | End-to-end шифрование, MTProto протокол |
| **Кроссплатформенность** | Web, iOS, Android, Windows, macOS, Linux |
| **Аудитория** | 800+ млн активных пользователей в месяц |
| **Функциональность** | Inline-режим, Web Apps, платежи, стикеры |
| **Бесплатность** | API полностью бесплатный без лимитов на сообщения |

### Типичные сценарии использования

- Автоматизация клиентской поддержки
- Уведомления и рассылки
- Интеграция с бизнес-системами
- Боты для продаж и бронирования
- **Для стоматологий:** запись на приём, консультации, напоминания

---

## 2. Архитектура интеграции

### Схема взаимодействия

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Пользователь│────▶│  Telegram   │────▶│ AGIents Bot │────▶│   AI/LLM    │
│ в Telegram  │◀────│  Server     │◀────│   Server    │◀────│   Engine    │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### Компоненты системы

1. **Telegram Bot** — точка входа для пользователей (создаётся через @BotFather)
2. **Telegram Bot API** — HTTPS интерфейс (api.telegram.org)
3. **Бот-сервер** — обработка событий и бизнес-логика
4. **AI Engine** — AGIents для генерации ответов

### Базовый URL API

```
https://api.telegram.org/bot<token>/METHOD_NAME
```

Где `<token>` — токен бота, полученный от @BotFather.

---

## 3. Создание и настройка бота

### Шаг 1: Создание бота через BotFather

1. Откройте Telegram и найдите [@BotFather](https://t.me/BotFather)
2. Отправьте команду `/newbot`
3. Введите отображаемое имя бота (например: "Стоматология Smile")
4. Введите username бота (должен заканчиваться на `bot`, например: `smile_dental_bot`)
5. Сохраните полученный **токен** (формат: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

> **Безопасность:** Никогда не публикуйте токен бота! При компрометации — немедленно отзовите через `/revoke` в BotFather.

### Шаг 2: Настройка бота

Команды BotFather для настройки:

| Команда | Описание |
|---------|----------|
| `/setname` | Изменить отображаемое имя |
| `/setdescription` | Установить описание (видно в профиле) |
| `/setabouttext` | Краткое описание (показывается при старте) |
| `/setuserpic` | Установить аватар бота |
| `/setcommands` | Настроить меню команд |
| `/setprivacy` | Режим приватности (группы) |
| `/setjoingroups` | Разрешить добавление в группы |

### Шаг 3: Настройка меню команд

Отправьте `/setcommands` в BotFather, затем список команд:

```
start - Начать работу с ботом
book - Записаться на приём
services - Услуги и цены
schedule - График работы
help - Помощь
```

### Шаг 4: Проверка работоспособности

```bash
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"
```

Ответ:
```json
{
  "ok": true,
  "result": {
    "id": 123456789,
    "is_bot": true,
    "first_name": "Стоматология Smile",
    "username": "smile_dental_bot",
    "can_join_groups": true,
    "can_read_all_group_messages": false,
    "supports_inline_queries": false
  }
}
```

---

## 4. Получение событий: Webhook vs Long Polling

### Сравнение подходов

| Параметр | Webhook | Long Polling (getUpdates) |
|----------|---------|---------------------------|
| **Направление** | Telegram → Ваш сервер | Ваш сервер → Telegram |
| **Требования** | Публичный HTTPS endpoint | Только исходящие запросы |
| **SSL** | Обязателен (можно self-signed) | Не требуется |
| **Масштабируемость** | Один endpoint | Одно соединение |
| **Задержка** | Мгновенно | До 60 сек (timeout) |
| **Firewall** | Нужен открытый порт | Работает за NAT |
| **Гарантия доставки** | Повторы при ошибках | Ручная обработка offset |

### Рекомендация для AGIents

**Для продакшена:** Webhook (надёжнее, мгновенная доставка)
**Для разработки/тестирования:** Long Polling (проще настроить)

---

## 4.1 Webhook

### Установка Webhook

```
POST https://api.telegram.org/bot<token>/setWebhook
```

**Параметры:**

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `url` | String | Да | HTTPS URL для получения обновлений |
| `certificate` | InputFile | Нет | Публичный ключ для self-signed сертификата |
| `ip_address` | String | Нет | Фиксированный IP для webhook |
| `max_connections` | Integer | Нет | Макс. одновременных соединений (1-100, по умолчанию 40) |
| `allowed_updates` | Array | Нет | Типы обновлений для получения |
| `drop_pending_updates` | Boolean | Нет | Удалить накопившиеся обновления |
| `secret_token` | String | Нет | Секретный токен для заголовка X-Telegram-Bot-Api-Secret-Token |

**Пример установки:**

```bash
curl -F "url=https://yourdomain.com/telegram/webhook" \
     -F "allowed_updates=[\"message\",\"callback_query\"]" \
     -F "secret_token=your_secret_token" \
     "https://api.telegram.org/bot<token>/setWebhook"
```

### Формат входящих обновлений (Update)

```json
{
  "update_id": 123456789,
  "message": {
    "message_id": 123,
    "from": {
      "id": 987654321,
      "is_bot": false,
      "first_name": "Иван",
      "last_name": "Петров",
      "username": "ivan_petrov",
      "language_code": "ru"
    },
    "chat": {
      "id": 987654321,
      "first_name": "Иван",
      "last_name": "Петров",
      "username": "ivan_petrov",
      "type": "private"
    },
    "date": 1642345678,
    "text": "Привет! Хочу записаться к стоматологу"
  }
}
```

### Обязательный ответ сервера

На **каждый** webhook-запрос сервер должен вернуть:
- HTTP Status: `200 OK`
- Тело может содержать метод API как ответ (опционально)

> Если сервер не отвечает или возвращает ошибку, Telegram будет повторять запросы с экспоненциальной задержкой.

### Допустимые порты для Webhook

Telegram поддерживает только порты:
- **443** (стандартный HTTPS)
- **80** (только HTTP → HTTPS редирект)
- **88**
- **8443**

### Пример обработчика (Go)

```go
package main

import (
    "encoding/json"
    "fmt"
    "io"
    "log"
    "net/http"
)

const (
    BotToken    = "YOUR_BOT_TOKEN"
    SecretToken = "your_secret_token"
)

type Update struct {
    UpdateID      int            `json:"update_id"`
    Message       *Message       `json:"message,omitempty"`
    CallbackQuery *CallbackQuery `json:"callback_query,omitempty"`
}

type Message struct {
    MessageID int    `json:"message_id"`
    From      *User  `json:"from"`
    Chat      *Chat  `json:"chat"`
    Date      int    `json:"date"`
    Text      string `json:"text,omitempty"`
}

type User struct {
    ID           int    `json:"id"`
    IsBot        bool   `json:"is_bot"`
    FirstName    string `json:"first_name"`
    LastName     string `json:"last_name,omitempty"`
    Username     string `json:"username,omitempty"`
    LanguageCode string `json:"language_code,omitempty"`
}

type Chat struct {
    ID        int64  `json:"id"`
    Type      string `json:"type"`
    Title     string `json:"title,omitempty"`
    Username  string `json:"username,omitempty"`
    FirstName string `json:"first_name,omitempty"`
    LastName  string `json:"last_name,omitempty"`
}

type CallbackQuery struct {
    ID           string   `json:"id"`
    From         *User    `json:"from"`
    Message      *Message `json:"message,omitempty"`
    ChatInstance string   `json:"chat_instance"`
    Data         string   `json:"data,omitempty"`
}

func webhookHandler(w http.ResponseWriter, r *http.Request) {
    // Проверка секретного токена
    if r.Header.Get("X-Telegram-Bot-Api-Secret-Token") != SecretToken {
        http.Error(w, "Unauthorized", http.StatusUnauthorized)
        return
    }

    body, err := io.ReadAll(r.Body)
    if err != nil {
        http.Error(w, "Bad Request", http.StatusBadRequest)
        return
    }

    var update Update
    if err := json.Unmarshal(body, &update); err != nil {
        http.Error(w, "Bad Request", http.StatusBadRequest)
        return
    }

    // Обработка в горутине для быстрого ответа
    go processUpdate(update)

    w.WriteHeader(http.StatusOK)
}

func processUpdate(update Update) {
    if update.Message != nil {
        handleMessage(update.Message)
    } else if update.CallbackQuery != nil {
        handleCallbackQuery(update.CallbackQuery)
    }
}

func main() {
    http.HandleFunc("/telegram/webhook", webhookHandler)
    log.Println("Starting Telegram Bot server on :8443")
    log.Fatal(http.ListenAndServeTLS(":8443", "cert.pem", "key.pem", nil))
}
```

### Удаление Webhook

```bash
curl "https://api.telegram.org/bot<token>/deleteWebhook?drop_pending_updates=true"
```

### Информация о Webhook

```bash
curl "https://api.telegram.org/bot<token>/getWebhookInfo"
```

---

## 4.2 Long Polling (getUpdates)

### Получение обновлений

```
GET https://api.telegram.org/bot<token>/getUpdates
?offset=LAST_UPDATE_ID+1
&limit=100
&timeout=60
&allowed_updates=["message","callback_query"]
```

**Параметры:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `offset` | Integer | ID первого обновления для получения |
| `limit` | Integer | Максимум обновлений (1-100, по умолчанию 100) |
| `timeout` | Integer | Таймаут long polling в секундах (0-60) |
| `allowed_updates` | Array | Типы обновлений |

### Пример (Python)

```python
import requests
import json
from typing import Generator, Dict, Any

class TelegramLongPoll:
    def __init__(self, token: str):
        self.token = token
        self.api_url = f"https://api.telegram.org/bot{token}"
        self.session = requests.Session()
        self.offset = 0

    def get_updates(self, timeout: int = 60) -> list:
        response = self.session.get(
            f"{self.api_url}/getUpdates",
            params={
                "offset": self.offset,
                "limit": 100,
                "timeout": timeout,
                "allowed_updates": json.dumps(["message", "callback_query"])
            },
            timeout=timeout + 10
        ).json()

        if not response.get("ok"):
            raise Exception(f"API Error: {response}")

        return response.get("result", [])

    def listen(self) -> Generator[Dict[str, Any], None, None]:
        while True:
            updates = self.get_updates()

            for update in updates:
                self.offset = update["update_id"] + 1
                yield update

    def send_message(self, chat_id: int, text: str, **kwargs) -> dict:
        payload = {
            "chat_id": chat_id,
            "text": text,
            **kwargs
        }
        response = self.session.post(
            f"{self.api_url}/sendMessage",
            json=payload
        ).json()
        return response

# Использование
bot = TelegramLongPoll(token="YOUR_BOT_TOKEN")

for update in bot.listen():
    if "message" in update:
        message = update["message"]
        chat_id = message["chat"]["id"]
        text = message.get("text", "")

        print(f"New message from {chat_id}: {text}")

        # Эхо-ответ
        bot.send_message(chat_id, f"Вы написали: {text}")
```

---

## 5. Работа с сообщениями

### Отправка сообщения (sendMessage)

```
POST https://api.telegram.org/bot<token>/sendMessage
```

**Обязательные параметры:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `chat_id` | Integer/String | ID чата или @username канала |
| `text` | String | Текст сообщения (до 4096 символов) |

**Опциональные параметры:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `parse_mode` | String | Форматирование: `HTML`, `Markdown`, `MarkdownV2` |
| `reply_markup` | Object | Клавиатура (InlineKeyboard или ReplyKeyboard) |
| `disable_web_page_preview` | Boolean | Отключить превью ссылок |
| `disable_notification` | Boolean | Без звука уведомления |
| `protect_content` | Boolean | Запретить пересылку/сохранение |
| `reply_to_message_id` | Integer | ID сообщения для ответа |

### Форматирование текста

**HTML:**
```html
<b>жирный</b>, <i>курсив</i>, <u>подчёркнутый</u>
<s>зачёркнутый</s>, <code>моноширинный</code>
<pre>блок кода</pre>
<a href="https://example.com">ссылка</a>
<tg-spoiler>спойлер</tg-spoiler>
```

**MarkdownV2:**
```
*жирный*, _курсив_, __подчёркнутый__
~зачёркнутый~, `моноширинный`
```код```
[ссылка](https://example.com)
||спойлер||
```

> **Важно:** В MarkdownV2 нужно экранировать символы: `_`, `*`, `[`, `]`, `(`, `)`, `~`, `` ` ``, `>`, `#`, `+`, `-`, `=`, `|`, `{`, `}`, `.`, `!`

### Пример отправки (Go)

```go
type SendMessageRequest struct {
    ChatID      int64       `json:"chat_id"`
    Text        string      `json:"text"`
    ParseMode   string      `json:"parse_mode,omitempty"`
    ReplyMarkup interface{} `json:"reply_markup,omitempty"`
}

func sendMessage(chatID int64, text string, keyboard interface{}) error {
    reqBody := SendMessageRequest{
        ChatID:      chatID,
        Text:        text,
        ParseMode:   "HTML",
        ReplyMarkup: keyboard,
    }

    jsonBody, _ := json.Marshal(reqBody)

    resp, err := http.Post(
        fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", BotToken),
        "application/json",
        bytes.NewBuffer(jsonBody),
    )
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    return nil
}
```

### Редактирование сообщения

```go
type EditMessageRequest struct {
    ChatID      int64       `json:"chat_id"`
    MessageID   int         `json:"message_id"`
    Text        string      `json:"text"`
    ParseMode   string      `json:"parse_mode,omitempty"`
    ReplyMarkup interface{} `json:"reply_markup,omitempty"`
}

func editMessage(chatID int64, messageID int, text string, keyboard interface{}) error {
    reqBody := EditMessageRequest{
        ChatID:      chatID,
        MessageID:   messageID,
        Text:        text,
        ParseMode:   "HTML",
        ReplyMarkup: keyboard,
    }

    jsonBody, _ := json.Marshal(reqBody)

    resp, err := http.Post(
        fmt.Sprintf("https://api.telegram.org/bot%s/editMessageText", BotToken),
        "application/json",
        bytes.NewBuffer(jsonBody),
    )
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    return nil
}
```

### Отправка с вложениями

```go
// Отправка фото
func sendPhoto(chatID int64, photoURL string, caption string) error {
    reqBody := map[string]interface{}{
        "chat_id": chatID,
        "photo":   photoURL,
        "caption": caption,
    }

    jsonBody, _ := json.Marshal(reqBody)

    _, err := http.Post(
        fmt.Sprintf("https://api.telegram.org/bot%s/sendPhoto", BotToken),
        "application/json",
        bytes.NewBuffer(jsonBody),
    )
    return err
}

// Отправка документа
func sendDocument(chatID int64, documentURL string, caption string) error {
    reqBody := map[string]interface{}{
        "chat_id":  chatID,
        "document": documentURL,
        "caption":  caption,
    }

    jsonBody, _ := json.Marshal(reqBody)

    _, err := http.Post(
        fmt.Sprintf("https://api.telegram.org/bot%s/sendDocument", BotToken),
        "application/json",
        bytes.NewBuffer(jsonBody),
    )
    return err
}
```

### Методы отправки медиа

| Метод | Описание |
|-------|----------|
| `sendPhoto` | Отправка изображения |
| `sendAudio` | Отправка аудиофайла |
| `sendDocument` | Отправка документа |
| `sendVideo` | Отправка видео |
| `sendVoice` | Отправка голосового сообщения |
| `sendVideoNote` | Отправка видеосообщения (кружок) |
| `sendLocation` | Отправка геолокации |
| `sendContact` | Отправка контакта |
| `sendMediaGroup` | Отправка альбома (2-10 медиа) |

---

## 6. Клавиатура бота

### Типы клавиатур

| Тип | Класс | Расположение | Особенности |
|-----|-------|--------------|-------------|
| Reply Keyboard | `ReplyKeyboardMarkup` | Под полем ввода | Заменяет стандартную клавиатуру |
| Inline Keyboard | `InlineKeyboardMarkup` | В сообщении | Кнопки-действия |

### Reply Keyboard (ReplyKeyboardMarkup)

```json
{
  "keyboard": [
    [
      {"text": "Записаться на приём"},
      {"text": "Мои записи"}
    ],
    [
      {"text": "Услуги и цены"},
      {"text": "График работы"}
    ],
    [
      {"text": "Позвонить", "request_contact": true}
    ],
    [
      {"text": "Отправить геолокацию", "request_location": true}
    ]
  ],
  "resize_keyboard": true,
  "one_time_keyboard": false,
  "input_field_placeholder": "Выберите действие..."
}
```

**Параметры ReplyKeyboardMarkup:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `keyboard` | Array of Array | Массив рядов кнопок |
| `resize_keyboard` | Boolean | Подгонять размер клавиатуры |
| `one_time_keyboard` | Boolean | Скрыть после нажатия |
| `input_field_placeholder` | String | Подсказка в поле ввода |
| `selective` | Boolean | Показать выборочно (в группах) |
| `is_persistent` | Boolean | Всегда показывать клавиатуру |

**Специальные кнопки Reply Keyboard:**

| Параметр | Описание |
|----------|----------|
| `request_contact` | Запросить номер телефона |
| `request_location` | Запросить геолокацию |
| `request_poll` | Создать опрос |
| `request_users` | Запросить выбор пользователей |
| `request_chat` | Запросить выбор чата |
| `web_app` | Открыть Web App |

### Inline Keyboard (InlineKeyboardMarkup)

```json
{
  "inline_keyboard": [
    [
      {
        "text": "Записаться",
        "callback_data": "book_appointment"
      },
      {
        "text": "Отмена",
        "callback_data": "cancel"
      }
    ],
    [
      {
        "text": "Выбрать дату",
        "callback_data": "select_date"
      }
    ],
    [
      {
        "text": "Позвонить",
        "url": "tel:+78001234567"
      }
    ],
    [
      {
        "text": "Наш сайт",
        "url": "https://example.com"
      }
    ],
    [
      {
        "text": "Открыть приложение",
        "web_app": {"url": "https://example.com/webapp"}
      }
    ]
  ]
}
```

**Типы Inline-кнопок:**

| Параметр | Описание |
|----------|----------|
| `callback_data` | Данные для callback_query (до 64 байт) |
| `url` | URL для открытия |
| `web_app` | Описание Web App |
| `login_url` | URL авторизации (Telegram Login) |
| `switch_inline_query` | Переключение в inline-режим |
| `switch_inline_query_current_chat` | Inline в текущем чате |
| `switch_inline_query_chosen_chat` | Inline с выбором чата |
| `pay` | Кнопка оплаты (только первая в первом ряду) |

### Скрытие Reply Keyboard

```json
{
  "remove_keyboard": true,
  "selective": false
}
```

### Структуры Go

```go
type ReplyKeyboardMarkup struct {
    Keyboard              [][]KeyboardButton `json:"keyboard"`
    ResizeKeyboard        bool               `json:"resize_keyboard,omitempty"`
    OneTimeKeyboard       bool               `json:"one_time_keyboard,omitempty"`
    InputFieldPlaceholder string             `json:"input_field_placeholder,omitempty"`
    Selective             bool               `json:"selective,omitempty"`
    IsPersistent          bool               `json:"is_persistent,omitempty"`
}

type KeyboardButton struct {
    Text            string `json:"text"`
    RequestContact  bool   `json:"request_contact,omitempty"`
    RequestLocation bool   `json:"request_location,omitempty"`
}

type InlineKeyboardMarkup struct {
    InlineKeyboard [][]InlineKeyboardButton `json:"inline_keyboard"`
}

type InlineKeyboardButton struct {
    Text         string  `json:"text"`
    URL          string  `json:"url,omitempty"`
    CallbackData string  `json:"callback_data,omitempty"`
    WebApp       *WebApp `json:"web_app,omitempty"`
}

type WebApp struct {
    URL string `json:"url"`
}
```

---

## 7. Обработка событий

### Основные типы обновлений (Update)

| Поле | Тип | Описание |
|------|-----|----------|
| `message` | Message | Новое входящее сообщение |
| `edited_message` | Message | Отредактированное сообщение |
| `channel_post` | Message | Новый пост в канале |
| `edited_channel_post` | Message | Отредактированный пост в канале |
| `callback_query` | CallbackQuery | Нажатие inline-кнопки |
| `inline_query` | InlineQuery | Inline-запрос |
| `chosen_inline_result` | ChosenInlineResult | Выбранный inline-результат |
| `pre_checkout_query` | PreCheckoutQuery | Запрос перед оплатой |
| `my_chat_member` | ChatMemberUpdated | Изменение статуса бота в чате |
| `chat_join_request` | ChatJoinRequest | Запрос на вступление в чат |

### Структура Message

```json
{
  "message_id": 123,
  "from": {
    "id": 987654321,
    "is_bot": false,
    "first_name": "Иван",
    "last_name": "Петров",
    "username": "ivan_petrov",
    "language_code": "ru"
  },
  "chat": {
    "id": 987654321,
    "first_name": "Иван",
    "last_name": "Петров",
    "username": "ivan_petrov",
    "type": "private"
  },
  "date": 1642345678,
  "text": "/start",
  "entities": [
    {
      "type": "bot_command",
      "offset": 0,
      "length": 6
    }
  ]
}
```

### Обработка команд

```go
func handleMessage(msg *Message) {
    if msg.Text == "" {
        return
    }

    // Проверка на команду
    if strings.HasPrefix(msg.Text, "/") {
        handleCommand(msg)
        return
    }

    // Обычное сообщение — отправляем в AGIents
    processWithAI(msg)
}

func handleCommand(msg *Message) {
    command := strings.Split(msg.Text, " ")[0]

    switch command {
    case "/start":
        sendWelcomeMessage(msg.Chat.ID)
    case "/book":
        startBookingFlow(msg.Chat.ID)
    case "/services":
        sendServicesList(msg.Chat.ID)
    case "/schedule":
        sendSchedule(msg.Chat.ID)
    case "/help":
        sendHelp(msg.Chat.ID)
    default:
        sendMessage(msg.Chat.ID, "Неизвестная команда. Используйте /help", nil)
    }
}
```

### Обработка Callback Query

```json
{
  "id": "1234567890123456789",
  "from": {
    "id": 987654321,
    "is_bot": false,
    "first_name": "Иван"
  },
  "message": {
    "message_id": 456,
    "chat": {
      "id": 987654321,
      "type": "private"
    },
    "date": 1642345678,
    "text": "Выберите услугу:"
  },
  "chat_instance": "-1234567890123456789",
  "data": "service_cleaning"
}
```

### Ответ на Callback Query

```go
func handleCallbackQuery(cq *CallbackQuery) {
    // Обязательно ответить на callback_query!
    answerCallbackQuery(cq.ID, "")

    chatID := cq.Message.Chat.ID

    switch cq.Data {
    case "book_appointment":
        // Редактируем сообщение с новой клавиатурой
        editMessage(chatID, cq.Message.MessageID,
            "Выберите услугу:",
            buildServicesKeyboard())

    case "service_cleaning":
        editMessage(chatID, cq.Message.MessageID,
            "Вы выбрали: Профессиональная чистка\n\nВыберите дату:",
            buildDateKeyboard())

    case "cancel":
        editMessage(chatID, cq.Message.MessageID,
            "Действие отменено.",
            nil)
    }
}

func answerCallbackQuery(callbackQueryID string, text string) {
    reqBody := map[string]interface{}{
        "callback_query_id": callbackQueryID,
    }

    if text != "" {
        reqBody["text"] = text
        reqBody["show_alert"] = false // true для модального окна
    }

    jsonBody, _ := json.Marshal(reqBody)

    http.Post(
        fmt.Sprintf("https://api.telegram.org/bot%s/answerCallbackQuery", BotToken),
        "application/json",
        bytes.NewBuffer(jsonBody),
    )
}
```

> **Важно:** На каждый `callback_query` нужно ответить методом `answerCallbackQuery` в течение 10 секунд, иначе пользователь увидит "часики" загрузки.

---

## 8. Безопасность

### Секретный токен (Webhook)

При установке webhook указывайте `secret_token`:

```bash
curl -F "url=https://yourdomain.com/webhook" \
     -F "secret_token=YOUR_SECRET_32_CHARS_MIN" \
     "https://api.telegram.org/bot<token>/setWebhook"
```

Проверяйте на сервере:
```go
func webhookHandler(w http.ResponseWriter, r *http.Request) {
    secretToken := r.Header.Get("X-Telegram-Bot-Api-Secret-Token")

    if secretToken != expectedSecretToken {
        http.Error(w, "Unauthorized", http.StatusUnauthorized)
        return
    }

    // ... обработка
}
```

### Проверка IP-адресов Telegram

Telegram отправляет webhook-запросы с IP-адресов:
- `149.154.160.0/20`
- `91.108.4.0/22`

```go
func isValidTelegramIP(ip string) bool {
    telegramRanges := []string{
        "149.154.160.0/20",
        "91.108.4.0/22",
    }

    parsedIP := net.ParseIP(ip)

    for _, cidr := range telegramRanges {
        _, network, _ := net.ParseCIDR(cidr)
        if network.Contains(parsedIP) {
            return true
        }
    }

    return false
}
```

### Валидация callback_data

Пользователи могут подделать callback_data. Используйте подписи:

```go
import (
    "crypto/hmac"
    "crypto/sha256"
    "encoding/hex"
)

func signCallbackData(data string, secret string) string {
    h := hmac.New(sha256.New, []byte(secret))
    h.Write([]byte(data))
    signature := hex.EncodeToString(h.Sum(nil))[:8]
    return data + ":" + signature
}

func verifyCallbackData(signedData string, secret string) (string, bool) {
    parts := strings.Split(signedData, ":")
    if len(parts) != 2 {
        return "", false
    }

    data := parts[0]
    signature := parts[1]

    expectedSignature := signCallbackData(data, secret)
    expectedParts := strings.Split(expectedSignature, ":")

    return data, signature == expectedParts[1]
}
```

### Rate Limiting

Telegram имеет лимиты:
- **Сообщения в чат:** ~30 сообщений/сек в один чат
- **Массовые рассылки:** ~30 сообщений/сек всего
- **Группы:** ~20 сообщений/минуту в группу

Реализуйте очередь для массовых рассылок:

```go
type MessageQueue struct {
    messages chan SendMessageRequest
}

func (q *MessageQueue) Start() {
    ticker := time.NewTicker(35 * time.Millisecond) // ~28 msg/sec

    for range ticker.C {
        select {
        case msg := <-q.messages:
            go sendMessage(msg.ChatID, msg.Text, msg.ReplyMarkup)
        default:
            // Очередь пуста
        }
    }
}
```

### SSL-сертификат для Webhook

Для production используйте сертификат от CA (Let's Encrypt, etc.).

Для разработки можно использовать self-signed:

```bash
# Создание self-signed сертификата
openssl req -newkey rsa:2048 -sha256 -nodes \
  -keyout private.key -x509 -days 365 -out public.pem \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=AGIents/CN=yourdomain.com"

# При установке webhook передайте сертификат
curl -F "url=https://yourdomain.com:8443/webhook" \
     -F "certificate=@public.pem" \
     "https://api.telegram.org/bot<token>/setWebhook"
```

---

## 9. Примеры реализации

### Полный пример бота (Go + AGIents)

```go
package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "io"
    "log"
    "net/http"
    "strings"
    "time"
)

type Config struct {
    BotToken        string
    SecretToken     string
    AGIentsEndpoint string
    AGIentsAPIKey   string
}

var config = Config{
    BotToken:        "YOUR_BOT_TOKEN",
    SecretToken:     "your_webhook_secret_token",
    AGIentsEndpoint: "https://api.agients.pro/v1/chat",
    AGIentsAPIKey:   "your_agients_api_key",
}

// Telegram Types
type Update struct {
    UpdateID      int            `json:"update_id"`
    Message       *Message       `json:"message,omitempty"`
    CallbackQuery *CallbackQuery `json:"callback_query,omitempty"`
}

type Message struct {
    MessageID int    `json:"message_id"`
    From      *User  `json:"from"`
    Chat      *Chat  `json:"chat"`
    Date      int    `json:"date"`
    Text      string `json:"text,omitempty"`
}

type User struct {
    ID           int64  `json:"id"`
    IsBot        bool   `json:"is_bot"`
    FirstName    string `json:"first_name"`
    LastName     string `json:"last_name,omitempty"`
    Username     string `json:"username,omitempty"`
    LanguageCode string `json:"language_code,omitempty"`
}

type Chat struct {
    ID        int64  `json:"id"`
    Type      string `json:"type"`
    FirstName string `json:"first_name,omitempty"`
    LastName  string `json:"last_name,omitempty"`
    Username  string `json:"username,omitempty"`
}

type CallbackQuery struct {
    ID           string   `json:"id"`
    From         *User    `json:"from"`
    Message      *Message `json:"message,omitempty"`
    ChatInstance string   `json:"chat_instance"`
    Data         string   `json:"data,omitempty"`
}

type InlineKeyboardMarkup struct {
    InlineKeyboard [][]InlineKeyboardButton `json:"inline_keyboard"`
}

type InlineKeyboardButton struct {
    Text         string `json:"text"`
    CallbackData string `json:"callback_data,omitempty"`
    URL          string `json:"url,omitempty"`
}

type ReplyKeyboardMarkup struct {
    Keyboard        [][]KeyboardButton `json:"keyboard"`
    ResizeKeyboard  bool               `json:"resize_keyboard"`
    OneTimeKeyboard bool               `json:"one_time_keyboard"`
}

type KeyboardButton struct {
    Text string `json:"text"`
}

// AGIents Types
type AGIentsRequest struct {
    AgentID  string                 `json:"agent_id"`
    UserID   string                 `json:"user_id"`
    Message  string                 `json:"message"`
    Channel  string                 `json:"channel"`
    Metadata map[string]interface{} `json:"metadata,omitempty"`
}

type AGIentsResponse struct {
    Response string `json:"response"`
    Actions  []struct {
        Type string                 `json:"type"`
        Data map[string]interface{} `json:"data"`
    } `json:"actions,omitempty"`
}

func main() {
    http.HandleFunc("/telegram/webhook", webhookHandler)

    log.Println("Starting Telegram Bot server on :8443")
    log.Fatal(http.ListenAndServeTLS(":8443", "cert.pem", "key.pem", nil))
}

func webhookHandler(w http.ResponseWriter, r *http.Request) {
    // Проверка секретного токена
    if r.Header.Get("X-Telegram-Bot-Api-Secret-Token") != config.SecretToken {
        http.Error(w, "Unauthorized", http.StatusUnauthorized)
        return
    }

    body, err := io.ReadAll(r.Body)
    if err != nil {
        http.Error(w, "Bad Request", http.StatusBadRequest)
        return
    }

    var update Update
    if err := json.Unmarshal(body, &update); err != nil {
        http.Error(w, "Bad Request", http.StatusBadRequest)
        return
    }

    go processUpdate(update)

    w.WriteHeader(http.StatusOK)
}

func processUpdate(update Update) {
    if update.Message != nil {
        handleMessage(update.Message)
    } else if update.CallbackQuery != nil {
        handleCallbackQuery(update.CallbackQuery)
    }
}

func handleMessage(msg *Message) {
    if msg.Text == "" {
        return
    }

    // Проверка на команду
    if strings.HasPrefix(msg.Text, "/") {
        handleCommand(msg)
        return
    }

    // Отправляем в AGIents для AI обработки
    response := callAGIents(msg)

    // Отправляем ответ
    sendMessage(msg.Chat.ID, response.Response, nil)
}

func handleCommand(msg *Message) {
    command := strings.Split(msg.Text, " ")[0]

    switch command {
    case "/start":
        sendWelcomeMessage(msg.Chat.ID, msg.From.FirstName)
    case "/book":
        startBookingFlow(msg.Chat.ID)
    case "/services":
        sendServicesList(msg.Chat.ID)
    case "/schedule":
        sendSchedule(msg.Chat.ID)
    case "/help":
        sendHelp(msg.Chat.ID)
    default:
        sendMessage(msg.Chat.ID, "Неизвестная команда. Используйте /help для списка команд.", nil)
    }
}

func handleCallbackQuery(cq *CallbackQuery) {
    // Обязательно ответить на callback
    answerCallbackQuery(cq.ID, "")

    chatID := cq.Message.Chat.ID

    switch cq.Data {
    case "book_appointment":
        editMessage(chatID, cq.Message.MessageID,
            "Выберите услугу:",
            buildServicesInlineKeyboard())

    case "service_cleaning":
        editMessage(chatID, cq.Message.MessageID,
            "Профессиональная чистка\n\nЦена: от 3 500 руб.\n\nВыберите дату:",
            buildDateKeyboard())

    case "service_treatment":
        editMessage(chatID, cq.Message.MessageID,
            "Лечение кариеса\n\nЦена: от 4 000 руб.\n\nВыберите дату:",
            buildDateKeyboard())

    case "my_appointments":
        sendMessage(chatID, "У вас пока нет активных записей.", nil)

    case "back_to_main":
        editMessage(chatID, cq.Message.MessageID,
            "Чем могу помочь?",
            buildMainInlineKeyboard())

    case "cancel":
        editMessage(chatID, cq.Message.MessageID,
            "Действие отменено. Напишите мне, если понадобится помощь!",
            nil)

    default:
        answerCallbackQuery(cq.ID, "Неизвестное действие")
    }
}

func callAGIents(msg *Message) AGIentsResponse {
    reqBody := AGIentsRequest{
        AgentID: "dental_clinic_bot",
        UserID:  fmt.Sprintf("%d", msg.From.ID),
        Message: msg.Text,
        Channel: "telegram",
        Metadata: map[string]interface{}{
            "chat_id":    msg.Chat.ID,
            "message_id": msg.MessageID,
            "username":   msg.From.Username,
            "first_name": msg.From.FirstName,
        },
    }

    jsonBody, _ := json.Marshal(reqBody)

    req, _ := http.NewRequest("POST", config.AGIentsEndpoint, bytes.NewBuffer(jsonBody))
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "Bearer "+config.AGIentsAPIKey)

    client := &http.Client{Timeout: 30 * time.Second}
    resp, err := client.Do(req)
    if err != nil {
        log.Printf("AGIents error: %v", err)
        return AGIentsResponse{Response: "Извините, произошла ошибка. Попробуйте позже."}
    }
    defer resp.Body.Close()

    var agResponse AGIentsResponse
    json.NewDecoder(resp.Body).Decode(&agResponse)

    return agResponse
}

func sendWelcomeMessage(chatID int64, firstName string) {
    text := fmt.Sprintf(`Добро пожаловать, %s!

Я бот стоматологической клиники и помогу вам:

• Записаться на приём
• Узнать о наших услугах и ценах
• Получить консультацию
• Узнать график работы

Чем могу помочь?`, firstName)

    sendMessage(chatID, text, buildMainKeyboard())
}

func startBookingFlow(chatID int64) {
    text := "Отлично! Давайте запишем вас на приём.\n\nВыберите услугу:"

    sendMessage(chatID, text, buildServicesInlineKeyboard())
}

func sendServicesList(chatID int64) {
    text := `<b>Наши услуги:</b>

🦷 <b>Профессиональная чистка</b>
   от 3 500 руб.

🦷 <b>Лечение кариеса</b>
   от 4 000 руб.

🦷 <b>Удаление зуба</b>
   от 2 500 руб.

🦷 <b>Имплантация</b>
   от 35 000 руб.

🦷 <b>Отбеливание</b>
   от 15 000 руб.

Для записи нажмите /book или кнопку ниже.`

    keyboard := &InlineKeyboardMarkup{
        InlineKeyboard: [][]InlineKeyboardButton{
            {{Text: "Записаться на приём", CallbackData: "book_appointment"}},
        },
    }

    sendMessageWithParseMode(chatID, text, "HTML", keyboard)
}

func sendSchedule(chatID int64) {
    text := `<b>График работы:</b>

📍 <b>Адрес:</b> ул. Примерная, д. 1

🕐 <b>Пн-Пт:</b> 9:00 - 21:00
🕐 <b>Сб:</b> 10:00 - 18:00
🕐 <b>Вс:</b> выходной

📞 <b>Телефон:</b> +7 (800) 123-45-67`

    keyboard := &InlineKeyboardMarkup{
        InlineKeyboard: [][]InlineKeyboardButton{
            {{Text: "Записаться", CallbackData: "book_appointment"}},
            {{Text: "Позвонить", URL: "tel:+78001234567"}},
        },
    }

    sendMessageWithParseMode(chatID, text, "HTML", keyboard)
}

func sendHelp(chatID int64) {
    text := `<b>Доступные команды:</b>

/start - Начать работу с ботом
/book - Записаться на приём
/services - Услуги и цены
/schedule - График работы
/help - Эта справка

Также вы можете просто написать мне свой вопрос, и я постараюсь помочь!`

    sendMessageWithParseMode(chatID, text, "HTML", nil)
}

func buildMainKeyboard() *ReplyKeyboardMarkup {
    return &ReplyKeyboardMarkup{
        Keyboard: [][]KeyboardButton{
            {{Text: "Записаться на приём"}, {Text: "Мои записи"}},
            {{Text: "Услуги и цены"}, {Text: "График работы"}},
            {{Text: "Задать вопрос"}},
        },
        ResizeKeyboard: true,
    }
}

func buildMainInlineKeyboard() *InlineKeyboardMarkup {
    return &InlineKeyboardMarkup{
        InlineKeyboard: [][]InlineKeyboardButton{
            {{Text: "Записаться на приём", CallbackData: "book_appointment"}},
            {{Text: "Мои записи", CallbackData: "my_appointments"}},
        },
    }
}

func buildServicesInlineKeyboard() *InlineKeyboardMarkup {
    return &InlineKeyboardMarkup{
        InlineKeyboard: [][]InlineKeyboardButton{
            {{Text: "Профессиональная чистка", CallbackData: "service_cleaning"}},
            {{Text: "Лечение кариеса", CallbackData: "service_treatment"}},
            {{Text: "Удаление зуба", CallbackData: "service_extraction"}},
            {{Text: "Имплантация", CallbackData: "service_implant"}},
            {{Text: "← Назад", CallbackData: "back_to_main"}},
        },
    }
}

func buildDateKeyboard() *InlineKeyboardMarkup {
    return &InlineKeyboardMarkup{
        InlineKeyboard: [][]InlineKeyboardButton{
            {
                {Text: "Пн 23", CallbackData: "date_2026-01-23"},
                {Text: "Вт 24", CallbackData: "date_2026-01-24"},
                {Text: "Ср 25", CallbackData: "date_2026-01-25"},
            },
            {
                {Text: "Чт 26", CallbackData: "date_2026-01-26"},
                {Text: "Пт 27", CallbackData: "date_2026-01-27"},
                {Text: "Сб 28", CallbackData: "date_2026-01-28"},
            },
            {{Text: "← Назад к услугам", CallbackData: "book_appointment"}},
            {{Text: "✕ Отмена", CallbackData: "cancel"}},
        },
    }
}

func sendMessage(chatID int64, text string, keyboard interface{}) {
    sendMessageWithParseMode(chatID, text, "", keyboard)
}

func sendMessageWithParseMode(chatID int64, text string, parseMode string, keyboard interface{}) {
    reqBody := map[string]interface{}{
        "chat_id": chatID,
        "text":    text,
    }

    if parseMode != "" {
        reqBody["parse_mode"] = parseMode
    }

    if keyboard != nil {
        reqBody["reply_markup"] = keyboard
    }

    jsonBody, _ := json.Marshal(reqBody)

    resp, err := http.Post(
        fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", config.BotToken),
        "application/json",
        bytes.NewBuffer(jsonBody),
    )
    if err != nil {
        log.Printf("Send message error: %v", err)
        return
    }
    defer resp.Body.Close()
}

func editMessage(chatID int64, messageID int, text string, keyboard interface{}) {
    reqBody := map[string]interface{}{
        "chat_id":    chatID,
        "message_id": messageID,
        "text":       text,
    }

    if keyboard != nil {
        reqBody["reply_markup"] = keyboard
    }

    jsonBody, _ := json.Marshal(reqBody)

    resp, err := http.Post(
        fmt.Sprintf("https://api.telegram.org/bot%s/editMessageText", config.BotToken),
        "application/json",
        bytes.NewBuffer(jsonBody),
    )
    if err != nil {
        log.Printf("Edit message error: %v", err)
        return
    }
    defer resp.Body.Close()
}

func answerCallbackQuery(callbackQueryID string, text string) {
    reqBody := map[string]interface{}{
        "callback_query_id": callbackQueryID,
    }

    if text != "" {
        reqBody["text"] = text
    }

    jsonBody, _ := json.Marshal(reqBody)

    http.Post(
        fmt.Sprintf("https://api.telegram.org/bot%s/answerCallbackQuery", config.BotToken),
        "application/json",
        bytes.NewBuffer(jsonBody),
    )
}
```

---

## 10. Рекомендации для стоматологий

### Специфика B2B-партнёра

Для сети стоматологий рекомендуется реализовать:

### Основной функционал

1. **Запись на приём**
   - Выбор клиники (филиала)
   - Выбор врача/специализации
   - Выбор даты и времени
   - Подтверждение записи

2. **Напоминания**
   - За сутки до приёма
   - За 2 часа до приёма
   - Возможность отмены/переноса

3. **Консультации**
   - Ответы на типовые вопросы (AI)
   - Переключение на живого оператора
   - Отправка фото (для предварительной оценки)

4. **Информация**
   - Услуги и цены
   - Адреса и график работы
   - Акции и специальные предложения

### Пример клавиатуры для стоматологии

**Reply Keyboard (постоянная):**

```json
{
  "keyboard": [
    [
      {"text": "Записаться"},
      {"text": "Мои записи"}
    ],
    [
      {"text": "Услуги и цены"},
      {"text": "Наши клиники"}
    ],
    [
      {"text": "Задать вопрос"}
    ]
  ],
  "resize_keyboard": true,
  "is_persistent": true
}
```

**Inline Keyboard (для выбора услуги):**

```json
{
  "inline_keyboard": [
    [
      {"text": "Профессиональная чистка • от 3 500 ₽", "callback_data": "service:cleaning"}
    ],
    [
      {"text": "Лечение кариеса • от 4 000 ₽", "callback_data": "service:treatment"}
    ],
    [
      {"text": "Удаление зуба • от 2 500 ₽", "callback_data": "service:extraction"}
    ],
    [
      {"text": "Имплантация • от 35 000 ₽", "callback_data": "service:implant"}
    ],
    [
      {"text": "← Назад", "callback_data": "back:main"}
    ]
  ]
}
```

### Отправка напоминаний

```go
func sendAppointmentReminder(chatID int64, appointment Appointment) {
    text := fmt.Sprintf(`🦷 <b>Напоминание о записи</b>

📅 <b>Дата:</b> %s
🕐 <b>Время:</b> %s
👨‍⚕️ <b>Врач:</b> %s
📍 <b>Клиника:</b> %s

Ждём вас!`,
        appointment.Date.Format("02.01.2006"),
        appointment.Time,
        appointment.DoctorName,
        appointment.ClinicAddress,
    )

    keyboard := &InlineKeyboardMarkup{
        InlineKeyboard: [][]InlineKeyboardButton{
            {{Text: "✓ Подтвердить", CallbackData: fmt.Sprintf("confirm:%d", appointment.ID)}},
            {{Text: "↻ Перенести", CallbackData: fmt.Sprintf("reschedule:%d", appointment.ID)}},
            {{Text: "✕ Отменить", CallbackData: fmt.Sprintf("cancel_apt:%d", appointment.ID)}},
        },
    }

    sendMessageWithParseMode(chatID, text, "HTML", keyboard)
}
```

### Интеграция с CRM

Рекомендуемый flow:
1. Пользователь выбирает услугу → Telegram Bot
2. Bot запрашивает свободные слоты → AGIents → CRM стоматологии
3. Пользователь выбирает время → AGIents создаёт запись в CRM
4. CRM отправляет подтверждение → AGIents → Telegram пользователю

### Web App для расширенного UI

Для сложных сценариев (выбор из календаря, карта клиник) используйте Telegram Web Apps:

```json
{
  "inline_keyboard": [
    [
      {
        "text": "Выбрать на карте",
        "web_app": {"url": "https://yourdomain.com/webapp/map"}
      }
    ],
    [
      {
        "text": "Календарь записи",
        "web_app": {"url": "https://yourdomain.com/webapp/calendar"}
      }
    ]
  ]
}
```

---

## 11. Ссылки на документацию

### Официальная документация Telegram

| Раздел | URL |
|--------|-----|
| Bot API | https://core.telegram.org/bots/api |
| Введение в ботов | https://core.telegram.org/bots |
| Руководство по ботам | https://core.telegram.org/bots/features |
| Inline-режим | https://core.telegram.org/bots/inline |
| Web Apps | https://core.telegram.org/bots/webapps |
| Платежи | https://core.telegram.org/bots/payments |
| Список изменений API | https://core.telegram.org/bots/api-changelog |

### SDK и библиотеки

| Язык | Библиотека | GitHub |
|------|------------|--------|
| Go | telebot | https://github.com/tucnak/telebot |
| Go | telegram-bot-api | https://github.com/go-telegram-bot-api/telegram-bot-api |
| Python | python-telegram-bot | https://github.com/python-telegram-bot/python-telegram-bot |
| Python | aiogram | https://github.com/aiogram/aiogram |
| Node.js | node-telegram-bot-api | https://github.com/yagop/node-telegram-bot-api |
| Node.js | telegraf | https://github.com/telegraf/telegraf |
| PHP | telegram-bot-sdk | https://github.com/irazasyed/telegram-bot-sdk |
| Java | TelegramBots | https://github.com/rubenlagus/TelegramBots |
| Rust | teloxide | https://github.com/teloxide/teloxide |

### Полезные инструменты

| Инструмент | Описание | URL |
|------------|----------|-----|
| @BotFather | Создание и управление ботами | https://t.me/BotFather |
| @BotSupport | Поддержка разработчиков ботов | https://t.me/BotSupport |
| Bot API Test | Тестирование методов API | Через curl/Postman |

---

## Чеклист интеграции

- [ ] Создан бот через @BotFather
- [ ] Получен и сохранён токен бота
- [ ] Настроено имя, описание и аватар бота
- [ ] Настроено меню команд (/setcommands)
- [ ] Настроен Webhook или Long Polling
- [ ] Реализована обработка /start
- [ ] Реализована обработка команд
- [ ] Реализована обработка текстовых сообщений
- [ ] Реализована обработка callback_query
- [ ] Настроена Reply Keyboard
- [ ] Настроена Inline Keyboard
- [ ] Интегрирован AGIents для AI-ответов
- [ ] Настроена безопасность (secret_token, валидация)
- [ ] Протестированы все сценарии
- [ ] Настроено логирование и мониторинг

---

*Документ подготовлен для проекта AGIents.pro*
*При вопросах: обращаться в техническую поддержку*
