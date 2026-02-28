# Руководство по интеграции VK Bot API для AGIents

**Версия:** 1.0
**Дата:** 21 января 2026
**Автор:** AGIents.pro
**Целевая аудитория:** Разработчики, интегрирующие ИИ-ботов в VK

---

## Оглавление

1. [Обзор VK Bot API](#1-обзор-vk-bot-api)
2. [Архитектура интеграции](#2-архитектура-интеграции)
3. [Настройка сообщества VK](#3-настройка-сообщества-vk)
4. [Получение событий: Callback API vs Long Poll](#4-получение-событий-callback-api-vs-long-poll)
5. [Работа с сообщениями](#5-работа-с-сообщениями)
6. [Клавиатура бота](#6-клавиатура-бота)
7. [Обработка событий](#7-обработка-событий)
8. [Безопасность](#8-безопасность)
9. [Примеры реализации](#9-примеры-реализации)
10. [Рекомендации для стоматологий](#10-рекомендации-для-стоматологий)
11. [Ссылки на документацию](#11-ссылки-на-документацию)

---

## 1. Обзор VK Bot API

### Что такое VK Bot

**Бот** — программа, имитирующая действия человека для автоматизации рутинных задач. ВКонтакте боты работают через **сообщения сообществ** — привычный интерфейс для пользователей.

### Преимущества платформы VK

| Преимущество | Описание |
|--------------|----------|
| **Социальный граф** | Доступ к связям и интересам пользователей для персонализации |
| **Мультимедиа** | Огромная библиотека контента (фото, видео, аудио) |
| **Кроссплатформенность** | Работает в веб, мобильных приложениях, VK Messenger |
| **Аудитория** | ~100 млн активных пользователей в месяц |

### Типичные сценарии использования

- Обработка однотипных обращений
- Организация рассылок подписчикам
- Фильтрация заявок в системах поддержки
- Мгновенная реакция на сообщения
- **Для стоматологий:** запись на приём, консультации, напоминания

---

## 2. Архитектура интеграции

### Схема взаимодействия

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Пользователь│────▶│  VK Server  │────▶│ AGIents Bot │────▶│   AI/LLM    │
│   в VK      │◀────│  (API)      │◀────│   Server    │◀────│   Engine    │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### Компоненты системы

1. **Сообщество VK** — точка входа для пользователей
2. **VK API** — интерфейс взаимодействия (api.vk.ru)
3. **Бот-сервер** — обработка событий и логика
4. **AI Engine** — AGIents для генерации ответов

### Требуемая версия API

> **Важно:** С 1 декабря 2024 года поддерживаются только версии API **5.81 и выше**. Рекомендуется использовать **5.199** или актуальную версию.

---

## 3. Настройка сообщества VK

### Шаг 1: Создание/выбор сообщества

Можно использовать:
- Группу
- Публичную страницу
- Встречу (мероприятие)

### Шаг 2: Включение сообщений

1. Перейти в **Управление → Сообщения**
2. Включить **Сообщения сообщества**
3. Сохранить изменения

### Шаг 3: Настройка бота

1. Перейти в **Управление → Сообщения → Настройки для бота**
2. Включить **Возможности ботов**
3. Опционально: включить **Добавить кнопку «Начать»**
4. Опционально: **Разрешать добавлять сообщество в беседы**

### Шаг 4: Получение ключа доступа (Access Token)

1. **Управление → Дополнительно → Работа с API**
2. Нажать **Создать ключ**
3. Отметить необходимые права:
   - `messages` — для работы с сообщениями
   - `photos` — для отправки изображений
   - `docs` — для отправки документов
   - `manage` — для управления сообществом

> **Безопасность:** Никогда не публикуйте ключ доступа! При компрометации — немедленно удалите и создайте новый.

---

## 4. Получение событий: Callback API vs Long Poll

### Сравнение подходов

| Параметр | Callback API | Bots Long Poll API |
|----------|--------------|-------------------|
| **Направление** | VK → Ваш сервер | Ваш сервер → VK |
| **Требования** | Публичный HTTPS endpoint | Только исходящие запросы |
| **SSL** | Обязателен | Не требуется |
| **Масштабируемость** | До 10 серверов | 1 соединение |
| **Задержка** | Мгновенно | До 25 сек (wait) |
| **Firewall** | Нужен открытый порт | Работает за NAT |

### Рекомендация для AGIents

**Для продакшена:** Callback API (надёжнее, масштабируемее)
**Для разработки/тестирования:** Long Poll API (проще настроить)

---

## 4.1 Callback API

### Подключение

1. **Управление → Дополнительно → Работа с API → Callback API**
2. Указать URL вашего сервера (HTTPS)
3. Получить строку подтверждения
4. Настроить сервер для возврата этой строки
5. Подтвердить адрес

### Формат запросов от VK

```json
{
  "type": "message_new",
  "event_id": "unique_event_id",
  "v": "5.199",
  "object": {
    "message": { ... },
    "client_info": { ... }
  },
  "group_id": 123456
}
```

### Обязательный ответ сервера

На **каждое** уведомление сервер должен вернуть:
- HTTP Status: `200`
- Body: `ok`

> Если сервер несколько раз подряд вернёт ошибку, Callback API временно перестанет отправлять уведомления.

### Повторные попытки (X-Retry-Counter)

При неудачной доставке VK повторяет запросы:
1. Через 10 секунд
2. Через 3 минуты
3. Через 10 минут
4. Через 30 минут
5. Через 1 час

### Пример обработчика (Go)

```go
package main

import (
    "encoding/json"
    "fmt"
    "io"
    "net/http"
)

const (
    ConfirmationToken = "your_confirmation_string"
    AccessToken       = "your_access_token"
    APIVersion        = "5.199"
)

type CallbackEvent struct {
    Type    string          `json:"type"`
    Object  json.RawMessage `json:"object"`
    GroupID int             `json:"group_id"`
    EventID string          `json:"event_id"`
    V       string          `json:"v"`
    Secret  string          `json:"secret"`
}

type MessageNew struct {
    Message    Message    `json:"message"`
    ClientInfo ClientInfo `json:"client_info"`
}

type Message struct {
    ID        int    `json:"id"`
    PeerID    int    `json:"peer_id"`
    FromID    int    `json:"from_id"`
    Text      string `json:"text"`
    Date      int    `json:"date"`
    Payload   string `json:"payload,omitempty"`
}

type ClientInfo struct {
    ButtonActions  []string `json:"button_actions"`
    Keyboard       bool     `json:"keyboard"`
    InlineKeyboard bool     `json:"inline_keyboard"`
    Carousel       bool     `json:"carousel"`
    LangID         int      `json:"lang_id"`
}

func callbackHandler(w http.ResponseWriter, r *http.Request) {
    body, _ := io.ReadAll(r.Body)

    var event CallbackEvent
    json.Unmarshal(body, &event)

    switch event.Type {
    case "confirmation":
        fmt.Fprint(w, ConfirmationToken)
        return

    case "message_new":
        var msgNew MessageNew
        json.Unmarshal(event.Object, &msgNew)

        // Обработка сообщения через AGIents
        go handleMessage(msgNew.Message)

    case "message_event":
        // Обработка callback-кнопок
        go handleCallbackButton(event.Object)
    }

    fmt.Fprint(w, "ok")
}

func main() {
    http.HandleFunc("/callback", callbackHandler)
    http.ListenAndServeTLS(":443", "cert.pem", "key.pem", nil)
}
```

---

## 4.2 Bots Long Poll API

### Получение сервера Long Poll

```
GET https://api.vk.ru/method/groups.getLongPollServer
?group_id=YOUR_GROUP_ID
&access_token=YOUR_TOKEN
&v=5.199
```

Ответ:
```json
{
  "response": {
    "key": "abc123...",
    "server": "https://lp.vk.com/wh123456",
    "ts": "1"
  }
}
```

### Получение событий

```
GET {server}?act=a_check&key={key}&ts={ts}&wait=25
```

Ответ:
```json
{
  "ts": "2",
  "updates": [
    {
      "type": "message_new",
      "object": { ... },
      "group_id": 123456
    }
  ]
}
```

### Пример (Python)

```python
import requests
import json

class VKLongPoll:
    def __init__(self, token: str, group_id: int):
        self.token = token
        self.group_id = group_id
        self.api_version = "5.199"
        self.session = requests.Session()

    def get_server(self):
        response = self.session.get(
            "https://api.vk.ru/method/groups.getLongPollServer",
            params={
                "group_id": self.group_id,
                "access_token": self.token,
                "v": self.api_version
            }
        ).json()
        return response["response"]

    def listen(self):
        server = self.get_server()

        while True:
            response = self.session.get(
                server["server"],
                params={
                    "act": "a_check",
                    "key": server["key"],
                    "ts": server["ts"],
                    "wait": 25
                }
            ).json()

            if "failed" in response:
                if response["failed"] == 1:
                    server["ts"] = response["ts"]
                else:
                    server = self.get_server()
                continue

            server["ts"] = response["ts"]

            for update in response.get("updates", []):
                yield update

# Использование
lp = VKLongPoll(token="YOUR_TOKEN", group_id=123456)

for event in lp.listen():
    if event["type"] == "message_new":
        message = event["object"]["message"]
        print(f"New message: {message['text']}")
```

---

## 5. Работа с сообщениями

### Отправка сообщения (messages.send)

```
POST https://api.vk.ru/method/messages.send
```

**Обязательные параметры:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `peer_id` | integer | ID получателя (user_id или 2000000000 + chat_id) |
| `random_id` | integer | Уникальный ID для предотвращения дублей |
| `message` | string | Текст сообщения (до 4096 символов) |
| `access_token` | string | Ключ доступа сообщества |
| `v` | string | Версия API |

**Опциональные параметры:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `keyboard` | string | JSON клавиатуры |
| `attachment` | string | Вложения (photo, doc, audio_message) |
| `template` | string | Карусель или другой шаблон |
| `dont_parse_links` | integer | Не создавать сниппет для ссылок |
| `disable_mentions` | integer | Отключить уведомления об упоминаниях |

### Пример отправки (Go)

```go
func sendMessage(peerID int, text string, keyboard *Keyboard) error {
    params := url.Values{
        "peer_id":      {strconv.Itoa(peerID)},
        "message":      {text},
        "random_id":    {strconv.FormatInt(rand.Int63(), 10)},
        "access_token": {AccessToken},
        "v":            {APIVersion},
    }

    if keyboard != nil {
        kb, _ := json.Marshal(keyboard)
        params.Set("keyboard", string(kb))
    }

    resp, err := http.PostForm(
        "https://api.vk.ru/method/messages.send",
        params,
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
// Формат attachment: {type}{owner_id}_{media_id}
// Пример: photo-123456_789012

params.Set("attachment", "photo-123456_789012,doc-123456_789013")
```

---

## 6. Клавиатура бота

### Типы клавиатур

| Тип | inline | Максимум кнопок | Расположение |
|-----|--------|-----------------|--------------|
| Клавиатура чата | false | 40 (10 рядов × 5) | Под полем ввода |
| Inline-клавиатура | true | 10 (6 рядов × 5) | В сообщении |

### Структура клавиатуры

```json
{
  "one_time": false,
  "inline": false,
  "buttons": [
    [
      {
        "action": {
          "type": "text",
          "label": "Записаться",
          "payload": "{\"action\": \"book\"}"
        },
        "color": "primary"
      },
      {
        "action": {
          "type": "text",
          "label": "Консультация",
          "payload": "{\"action\": \"consult\"}"
        },
        "color": "secondary"
      }
    ],
    [
      {
        "action": {
          "type": "callback",
          "label": "Мои записи",
          "payload": "{\"action\": \"my_appointments\"}"
        },
        "color": "positive"
      }
    ]
  ]
}
```

### Типы кнопок

| Тип | Описание | Поля |
|-----|----------|------|
| `text` | Отправляет сообщение с текстом label | label, payload |
| `callback` | Отправляет событие без сообщения | label, payload |
| `open_link` | Открывает ссылку | label, link |
| `location` | Запрос геолокации | payload |
| `vkpay` | Оплата через VK Pay | hash |
| `open_app` | Открывает мини-приложение | app_id, label, owner_id, hash |

### Цвета кнопок

| Цвет | Константа | Использование |
|------|-----------|---------------|
| Синий | `primary` | Основное действие |
| Белый/серый | `secondary` | Обычные кнопки |
| Красный | `negative` | Отмена, удаление |
| Зелёный | `positive` | Подтверждение, согласие |

### Скрытие клавиатуры

```json
{
  "buttons": []
}
```

---

## 7. Обработка событий

### Основные события для ботов

| Событие | Описание |
|---------|----------|
| `message_new` | Новое входящее сообщение |
| `message_reply` | Исходящее сообщение от бота |
| `message_edit` | Редактирование сообщения |
| `message_event` | Нажатие callback-кнопки |
| `message_allow` | Пользователь разрешил сообщения |
| `message_deny` | Пользователь запретил сообщения |

### Структура message_new (v5.103+)

```json
{
  "type": "message_new",
  "object": {
    "message": {
      "id": 123,
      "date": 1642345678,
      "peer_id": 123456789,
      "from_id": 123456789,
      "text": "Привет! Хочу записаться к стоматологу",
      "payload": "{\"command\":\"start\"}"
    },
    "client_info": {
      "button_actions": ["text", "callback", "open_link"],
      "keyboard": true,
      "inline_keyboard": true,
      "carousel": true,
      "lang_id": 0
    }
  },
  "group_id": 123456
}
```

### Обработка callback-кнопок (message_event)

```json
{
  "type": "message_event",
  "object": {
    "user_id": 123456789,
    "peer_id": 123456789,
    "event_id": "abc123...",
    "payload": {"action": "book_appointment"},
    "conversation_message_id": 456
  },
  "group_id": 123456
}
```

### Ответ на callback-кнопку

```go
func sendMessageEventAnswer(eventID string, userID int, peerID int, eventData EventData) {
    data, _ := json.Marshal(eventData)

    params := url.Values{
        "event_id":     {eventID},
        "user_id":      {strconv.Itoa(userID)},
        "peer_id":      {strconv.Itoa(peerID)},
        "event_data":   {string(data)},
        "access_token": {AccessToken},
        "v":            {APIVersion},
    }

    http.PostForm(
        "https://api.vk.ru/method/messages.sendMessageEventAnswer",
        params,
    )
}

// Типы ответов:
// 1. Показать snackbar
eventData := EventData{Type: "show_snackbar", Text: "Запись подтверждена!"}

// 2. Открыть ссылку
eventData := EventData{Type: "open_link", Link: "https://example.com"}

// 3. Открыть мини-приложение
eventData := EventData{Type: "open_app", AppID: 123456}
```

---

## 8. Безопасность

### Секретный ключ (Secret Key)

Настройте в **Callback API → Секретный ключ**. Будет передаваться в каждом запросе:

```json
{
  "type": "message_new",
  "secret": "your_secret_key",
  ...
}
```

Проверяйте на сервере:
```go
if event.Secret != expectedSecret {
    http.Error(w, "Forbidden", http.StatusForbidden)
    return
}
```

### SSL-сертификат для Callback API

1. Серверный сертификат должен быть от авторизованного CA (например, Let's Encrypt)
2. Опционально: загрузите клиентский сертификат для двусторонней аутентификации

```bash
# Создание самоподписанного клиентского сертификата
openssl req -newkey rsa:2048 -sha256 -nodes \
  -keyout vkapi.key -x509 -days 365 -out vkapi.crt \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=AGIents/CN=vkapi"

# Экспорт в PKCS#12
openssl pkcs12 -export -in vkapi.crt -name "VK API" \
  -descert -inkey vkapi.key -out vkapi.p12
```

### Валидация payload

Пользователи могут подменять payload! Всегда проверяйте на сервере:

```go
var allowedActions = map[string]bool{
    "book":        true,
    "consult":     true,
    "cancel":      true,
    "my_records":  true,
}

func validatePayload(payload string) bool {
    var p struct {
        Action string `json:"action"`
    }
    json.Unmarshal([]byte(payload), &p)
    return allowedActions[p.Action]
}
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
    "math/rand"
    "net/http"
    "net/url"
    "strconv"
    "time"
)

type Config struct {
    ConfirmationToken string
    AccessToken       string
    SecretKey         string
    GroupID           int
    APIVersion        string
    AGIentsEndpoint   string
    AGIentsAPIKey     string
}

var config = Config{
    ConfirmationToken: "your_confirmation_string",
    AccessToken:       "your_vk_access_token",
    SecretKey:         "your_secret_key",
    GroupID:           123456,
    APIVersion:        "5.199",
    AGIentsEndpoint:   "https://api.agients.pro/v1/chat",
    AGIentsAPIKey:     "your_agients_api_key",
}

// VK Types
type CallbackEvent struct {
    Type    string          `json:"type"`
    Object  json.RawMessage `json:"object"`
    GroupID int             `json:"group_id"`
    Secret  string          `json:"secret"`
}

type MessageNewObject struct {
    Message    Message    `json:"message"`
    ClientInfo ClientInfo `json:"client_info"`
}

type Message struct {
    ID      int    `json:"id"`
    PeerID  int    `json:"peer_id"`
    FromID  int    `json:"from_id"`
    Text    string `json:"text"`
    Payload string `json:"payload,omitempty"`
}

type ClientInfo struct {
    ButtonActions  []string `json:"button_actions"`
    Keyboard       bool     `json:"keyboard"`
    InlineKeyboard bool     `json:"inline_keyboard"`
    Carousel       bool     `json:"carousel"`
}

type Keyboard struct {
    OneTime bool       `json:"one_time"`
    Inline  bool       `json:"inline"`
    Buttons [][]Button `json:"buttons"`
}

type Button struct {
    Action ButtonAction `json:"action"`
    Color  string       `json:"color,omitempty"`
}

type ButtonAction struct {
    Type    string `json:"type"`
    Label   string `json:"label,omitempty"`
    Payload string `json:"payload,omitempty"`
    Link    string `json:"link,omitempty"`
}

// AGIents Types
type AGIentsRequest struct {
    AgentID  string `json:"agent_id"`
    UserID   string `json:"user_id"`
    Message  string `json:"message"`
    Channel  string `json:"channel"`
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
    rand.Seed(time.Now().UnixNano())

    http.HandleFunc("/vk/callback", callbackHandler)

    log.Println("Starting VK Bot server on :8443")
    log.Fatal(http.ListenAndServeTLS(":8443", "cert.pem", "key.pem", nil))
}

func callbackHandler(w http.ResponseWriter, r *http.Request) {
    body, err := io.ReadAll(r.Body)
    if err != nil {
        http.Error(w, "Bad Request", http.StatusBadRequest)
        return
    }

    var event CallbackEvent
    if err := json.Unmarshal(body, &event); err != nil {
        http.Error(w, "Bad Request", http.StatusBadRequest)
        return
    }

    // Проверка секретного ключа
    if event.Secret != config.SecretKey {
        http.Error(w, "Forbidden", http.StatusForbidden)
        return
    }

    switch event.Type {
    case "confirmation":
        fmt.Fprint(w, config.ConfirmationToken)
        return

    case "message_new":
        var msgObj MessageNewObject
        json.Unmarshal(event.Object, &msgObj)
        go processMessage(msgObj)

    case "message_event":
        go processCallbackButton(event.Object)
    }

    fmt.Fprint(w, "ok")
}

func processMessage(msgObj MessageNewObject) {
    msg := msgObj.Message
    clientInfo := msgObj.ClientInfo

    // Проверка на команду start
    if msg.Payload == `{"command":"start"}` {
        sendWelcomeMessage(msg.PeerID, clientInfo)
        return
    }

    // Отправляем в AGIents для обработки AI
    response := callAGIents(msg)

    // Формируем клавиатуру на основе ответа
    var keyboard *Keyboard
    if clientInfo.Keyboard {
        keyboard = buildKeyboard(response, clientInfo)
    }

    sendMessage(msg.PeerID, response.Response, keyboard)
}

func callAGIents(msg Message) AGIentsResponse {
    reqBody := AGIentsRequest{
        AgentID: "dental_clinic_bot",
        UserID:  strconv.Itoa(msg.FromID),
        Message: msg.Text,
        Channel: "vk",
        Metadata: map[string]interface{}{
            "peer_id":    msg.PeerID,
            "message_id": msg.ID,
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

func sendWelcomeMessage(peerID int, clientInfo ClientInfo) {
    text := `Добро пожаловать в нашу стоматологическую клинику! 🦷

Я помогу вам:
• Записаться на приём
• Узнать о наших услугах
• Получить консультацию
• Узнать график работы

Чем могу помочь?`

    var keyboard *Keyboard
    if clientInfo.Keyboard {
        keyboard = &Keyboard{
            OneTime: false,
            Buttons: [][]Button{
                {
                    {Action: ButtonAction{Type: "text", Label: "Записаться на приём", Payload: `{"action":"book"}`}, Color: "primary"},
                },
                {
                    {Action: ButtonAction{Type: "text", Label: "Услуги и цены", Payload: `{"action":"services"}`}, Color: "secondary"},
                    {Action: ButtonAction{Type: "text", Label: "График работы", Payload: `{"action":"schedule"}`}, Color: "secondary"},
                },
                {
                    {Action: ButtonAction{Type: "callback", Label: "Мои записи", Payload: `{"action":"my_appointments"}`}, Color: "positive"},
                },
            },
        }
    }

    sendMessage(peerID, text, keyboard)
}

func buildKeyboard(response AGIentsResponse, clientInfo ClientInfo) *Keyboard {
    // Логика построения клавиатуры на основе ответа AGIents
    // Может возвращать nil если клавиатура не нужна
    return nil
}

func processCallbackButton(eventObj json.RawMessage) {
    var event struct {
        UserID               int             `json:"user_id"`
        PeerID               int             `json:"peer_id"`
        EventID              string          `json:"event_id"`
        Payload              json.RawMessage `json:"payload"`
        ConversationMsgID    int             `json:"conversation_message_id"`
    }
    json.Unmarshal(eventObj, &event)

    var payload struct {
        Action string `json:"action"`
    }
    json.Unmarshal(event.Payload, &payload)

    switch payload.Action {
    case "my_appointments":
        // Показываем snackbar и отправляем сообщение
        sendSnackbar(event.EventID, event.UserID, event.PeerID, "Загружаю ваши записи...")
        // Здесь логика получения записей пользователя

    default:
        sendSnackbar(event.EventID, event.UserID, event.PeerID, "Обрабатываю...")
    }
}

func sendMessage(peerID int, text string, keyboard *Keyboard) {
    params := url.Values{
        "peer_id":      {strconv.Itoa(peerID)},
        "message":      {text},
        "random_id":    {strconv.FormatInt(rand.Int63(), 10)},
        "access_token": {config.AccessToken},
        "v":            {config.APIVersion},
    }

    if keyboard != nil {
        kb, _ := json.Marshal(keyboard)
        params.Set("keyboard", string(kb))
    }

    resp, err := http.PostForm("https://api.vk.ru/method/messages.send", params)
    if err != nil {
        log.Printf("Send message error: %v", err)
        return
    }
    defer resp.Body.Close()
}

func sendSnackbar(eventID string, userID, peerID int, text string) {
    eventData, _ := json.Marshal(map[string]string{
        "type": "show_snackbar",
        "text": text,
    })

    params := url.Values{
        "event_id":     {eventID},
        "user_id":      {strconv.Itoa(userID)},
        "peer_id":      {strconv.Itoa(peerID)},
        "event_data":   {string(eventData)},
        "access_token": {config.AccessToken},
        "v":            {config.APIVersion},
    }

    http.PostForm("https://api.vk.ru/method/messages.sendMessageEventAnswer", params)
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

```json
{
  "one_time": false,
  "buttons": [
    [
      {
        "action": {"type": "text", "label": "Записаться", "payload": "{\"action\":\"book\"}"},
        "color": "primary"
      },
      {
        "action": {"type": "text", "label": "Мои записи", "payload": "{\"action\":\"my_appointments\"}"},
        "color": "secondary"
      }
    ],
    [
      {
        "action": {"type": "text", "label": "Услуги и цены", "payload": "{\"action\":\"services\"}"},
        "color": "secondary"
      },
      {
        "action": {"type": "text", "label": "Наши клиники", "payload": "{\"action\":\"clinics\"}"},
        "color": "secondary"
      }
    ],
    [
      {
        "action": {"type": "text", "label": "Задать вопрос", "payload": "{\"action\":\"question\"}"},
        "color": "secondary"
      }
    ],
    [
      {
        "action": {"type": "open_link", "label": "Позвонить", "link": "tel:+78001234567"},
        "color": "positive"
      }
    ]
  ]
}
```

### Карусель услуг

```json
{
  "type": "carousel",
  "elements": [
    {
      "photo_id": "-123456_789012",
      "title": "Профессиональная чистка",
      "description": "Удаление зубного камня и налёта",
      "buttons": [
        {"action": {"type": "text", "label": "от 3 500 ₽"}}
      ]
    },
    {
      "photo_id": "-123456_789013",
      "title": "Лечение кариеса",
      "description": "Современные материалы и методы",
      "buttons": [
        {"action": {"type": "text", "label": "от 4 000 ₽"}}
      ]
    }
  ]
}
```

### Интеграция с CRM

Рекомендуемый flow:
1. Пользователь выбирает услугу → AGIents
2. AGIents проверяет свободные слоты → CRM стоматологии
3. Пользователь выбирает время → AGIents создаёт запись в CRM
4. CRM отправляет подтверждение → AGIents → VK пользователю

---

## 11. Ссылки на документацию

### Официальная документация VK

| Раздел | URL |
|--------|-----|
| Боты для сообществ | https://dev.vk.com/ru/api/bots/overview |
| Быстрый старт | https://dev.vk.com/ru/api/bots/getting-started |
| Callback API | https://dev.vk.com/ru/api/callback/getting-started |
| Bots Long Poll API | https://dev.vk.com/ru/api/bots-long-poll/getting-started |
| Клавиатура | https://dev.vk.com/ru/api/bots/development/keyboard |
| События сообществ | https://dev.vk.com/ru/api/community-events/json-schema |
| Методы API | https://dev.vk.com/ru/method |
| Версии API | https://dev.vk.com/ru/reference/versions |

### SDK и библиотеки

| Язык | Библиотека | GitHub |
|------|------------|--------|
| PHP | VK PHP SDK | https://github.com/VKCOM/vk-php-sdk |
| Java | VK Java SDK | https://github.com/VKCOM/vk-java-sdk |
| Node.js | node-vk-bot-api | https://github.com/bifot/node-vk-bot-api |
| Python | vk_api | https://github.com/python273/vk_api |
| Go | vk-api (community) | https://github.com/SevereCloud/vksdk |

### Примеры ботов

- PHP Bot Example: https://github.com/VKCOM/bot-example-php
- Java YouTrack Bot: https://github.com/VKCOM/vk-java-sdk/wiki/YouTrack-bot

---

## Чеклист интеграции

- [ ] Создано/выбрано сообщество VK
- [ ] Включены сообщения сообщества
- [ ] Включены возможности ботов
- [ ] Получен ключ доступа с нужными правами
- [ ] Настроен Callback API или Long Poll
- [ ] Реализована обработка confirmation
- [ ] Реализована обработка message_new
- [ ] Реализована обработка message_event (callback-кнопки)
- [ ] Настроена клавиатура бота
- [ ] Интегрирован AGIents для AI-ответов
- [ ] Настроена безопасность (secret key, HTTPS)
- [ ] Протестированы все сценарии
- [ ] Настроено логирование и мониторинг

---

*Документ подготовлен для проекта AGIents.pro*
*При вопросах: обращаться в техническую поддержку*
