# RAG-системы - База знаний

**Цель:** Централизованное хранилище знаний о RAG (Retrieval-Augmented Generation) системах

---

## Содержание

Эта папка содержит материалы по:
- RAG архитектура и pipeline
- Chunking стратегии
- Embeddings и векторные БД
- Retrieval методы
- Reranking
- Advanced RAG техники
- Best practices

---

## Материалы для миграции из OLD_VAULT

### Приоритет: Q1 2026 (Неделя 2)

- [ ] **RAG from basics to advanced** (`/OLD_VAULT/Medium/RAG from basics to advanced.md`)
  - **ЦЕННЫЙ:** Полный обзор RAG pipeline
  - Chunking, embeddings, retrieval, reranking
  - **Применение:** Knowledge base для AGIents агентов

- [ ] **The Best Practices of RAG** (`/OLD_VAULT/Medium/The Best Practices of RAG.md`)
  - Best practices для production RAG
  - **Применение:** AGIents и Amaks implementation

### Приоритет: Q2 (По мере развития функционала)

- [ ] **What Nobody Tells You About RAGs** (`/OLD_VAULT/Medium/What Nobody Tells You About RAGs.md`)
- [ ] **RAG - Flow and Modular** (`/OLD_VAULT/Medium/RAG - Flow and Modular.md`)
- [ ] **Complex RAG** (`/OLD_VAULT/Medium/Complex RAG.md`)
- [ ] **Four-module Synergy for Enhancing RAG** (`/OLD_VAULT/Medium/Four-module Synergy for Enhancing RAG.md`)
- [ ] **High-Precision RAG for Table Heavy Documents** (`/OLD_VAULT/Medium/High-Precision RAG for Table Heavy Documents.md`)
- [ ] **RAG Chatbot** (`/OLD_VAULT/Medium/RAG Chatbot.md`)

### Приоритет: Q3 (Advanced темы)

- [ ] **Vector Embeddings Explained** (`/OLD_VAULT/Medium/Vector Embeddings Explained.md`)
- [ ] **Efficient Information Retrieval** (`/OLD_VAULT/Medium/Efficient Information Retrieval.md`)
- [ ] **Vector-only Database?** (`/OLD_VAULT/Medium/Vector-only Database.md`)
- [ ] **Knowledge Graphs - NER vs. LLMs** (`/OLD_VAULT/Medium/Knowledge Graphs - NER vs. LLMs.md`)

---

## Структура папки (после миграции)

```
RAG-системы/
├── README.md (этот файл)
├── Основы/
│   ├── RAG from basics to advanced.md
│   └── Best Practices.md
├── Advanced техники/
│   ├── Complex RAG.md
│   ├── Four-module Synergy.md
│   └── High-Precision RAG.md
├── Векторные БД/
│   ├── Vector Embeddings.md
│   └── Vector DB comparison.md
├── Применение/
│   ├── RAG для AGIents.md
│   ├── RAG для Amaks.md
│   └── Кейсы использования.md
└── Референсы/
    └── Useful links.md
```

---

## Применение в проектах

### AGIents.pro
- Knowledge base для агентов
- Semantic search по документации клиентов
- Context-aware ответы

### Amaks
- База знаний санатория
- FAQ система
- Поиск по услугам и ценам

### AI-код-ревью
- Поиск похожих паттернов кода
- Best practices database
- Code documentation search

---

## Связанные проекты

- [[AGIents.pro - ИИ-агенты платформа/README|AGIents.pro]] - основное применение
- [[Кейс Amaks]] - практическая реализация
- [[AI-код-ревью система/README|AI-код-ревью]] - возможное применение

---

*Создано: 2026-01-02*
*Обновлено: 2026-01-02*
