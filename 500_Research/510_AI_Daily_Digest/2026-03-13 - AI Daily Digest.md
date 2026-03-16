---
type: ai-daily-digest
date: 2026-03-13
platforms: [X/Twitter]
period: 2026-03-12 — 2026-03-13
status: completed
tags: [daily-digest, ai-news, auto-generated]
---

# AI Daily Digest — 2026-03-13

**Период:** 2026-03-12 — 2026-03-13
**Платформы:** X/Twitter

> AI-синтезированный анализ через Grok API (X/Twitter) + Firecrawl API (Reddit) + Claude (синтез)

---

## Top Stories

### 1. Claude добавил интерактивные charts прямо в чат
**Источник:** X | **Ссылка:** https://x.com/claudeai/status/2032124273587077133
Anthropic запустил beta-функцию: Claude теперь строит интерактивные диаграммы и графики непосредственно в диалоге. Доступно на всех планах. Пост набрал 29k лайков и 5M просмотров — один из самых резонансных релизов недели.

### 2. MCP protocol живёт в enterprise: Uber как кейс
**Источник:** X | **Ссылка:** https://x.com/GergelyOrosz/status/2032194904957268267
@GergelyOrosz (Pragmatic Engineer) опроверг тезис @levelsio о смерти MCP, раскрыв, что Uber использует MCPs как backbone для AI agents во внутренней инфраструктуре. Инсайдерский взгляд подтверждает: MCP — это enterprise-стандарт для tool use, а не хайп.

### 3. Gemini CLI v0.33.0 — Plan mode и slash commands
**Источник:** X | **Ссылка:** https://x.com/geminicli/status/2032123248767332429
Google выпустил крупное обновление open-source CLI: запущен Plan mode, улучшена поддержка ACP со slash commands, добавлены расширения Shopify и Canva. Прямая конкуренция с Claude Code в пространстве AI coding tools.

### 4. Claude Code skill для scraping целых docs-сайтов
**Источник:** X | **Ссылка:** https://x.com/RoundtableSpace/status/2031954587750396283
Разработчик создал Claude Code skill, использующий Cloudflare `/crawl` endpoint для загрузки целого сайта документации одной командой. В демо — 29 страниц Claude docs за один вызов. Яркий пример того, как skills расширяют function calling возможности агентов.

### 5. Claude-Scientific-Skills — open-source drug discovery в Claude Code
**Источник:** X | **Ссылка:** https://x.com/simplifyinAI/status/2032138383909130403
Плагин подключает Claude Code к 28+ научным базам данных (PubMed и др.) и позволяет запускать полные drug discovery pipelines без кода. Показывает экспансию AI agents за пределы software engineering в research-домены.

---

## X/Twitter Highlights

- **@claudeai** — [официальный анонс](https://x.com/claudeai/status/2032124273587077133): interactive charts и diagrams в Claude chat, beta на всех планах. 29k лайков, 5M views.

- **@GergelyOrosz** — [MCP в Uber](https://x.com/GergelyOrosz/status/2032194904957268267): "MCPs are the opposite of dead. They are the life blood of how AI agents use services inside mid-sized and above companies." Контраргумент @levelsio, 800 лайков.

- **@geminicli** — [Gemini CLI v0.33.0](https://x.com/geminicli/status/2032123248767332429): Plan mode, ACP slash commands, Shopify/Canva extensions. 1.3k лайков.

- **@RoundtableSpace** — [Cloudflare crawl skill для Claude Code](https://x.com/RoundtableSpace/status/2031954587750396283): scraping 29 страниц docs за одну команду, 672 лайка.

- **@simplifyinAI** — [Claude-Scientific-Skills](https://x.com/simplifyinAI/status/2032138383909130403): 28+ scientific databases, drug discovery pipelines, 100% open-source, 194 лайка.

- **@tom_doerr** — [multi-agent robot coordination framework](https://x.com/tom_doerr/status/2032145432852250692): LLM discussion framework для координации роботов, [github.com/yongchao98/multi-agent-framework](https://github.com/yongchao98/multi-agent-framework).

- **@causalinf** (экономист-профессор) — [скептицизм по поводу Claude Code](https://x.com/causalinf/status/2032093505548320950): "If I have to start reading the freaking source code of every package just to use it, I'm going to be a little ambivalent abt the gains to labor productivity from Claude code." Редкий критический взгляд на реальную productivity AI agents.

---

## Reddit Discussions

*Данные за период недоступны.*

---

## Тренды дня

- **Claude Code как экосистема**: skills, plugins, loops — платформа быстро обрастает community-driven расширениями
- **MCP в enterprise**: дискуссия Orosz vs levelsio подтвердила, что MCP protocol укореняется в крупных компаниях (Uber), не умирает
- **Plan mode как стандарт**: и Claude Code, и Gemini CLI одновременно развивают planning capabilities — становится базовым ожиданием от AI coding tools
- **AI agents за пределами кода**: научные workflows (drug discovery, PubMed) — следующий фронтир для agentic tool use
- **Productivity backlash**: начинает звучать критика реальных gains от AI coding tools — сигнал зрелости дискуссии

---

## Релевантность для проектов

### AGIents.pro

- Кейс Uber с MCP — сильный social proof для enterprise-питча платформы AI-агентов; можно использовать как reference point для позиционирования
- Рост Claude Code skills экосистемы показывает: пользователи хотят composable, pluggable agents — стоит убедиться, что AGIents.pro поддерживает эту модель расширяемости
- Plan mode в Gemini CLI и Claude Code — если платформа не имеет аналогичной функции планирования для агентов, это gap, который стоит закрыть
- Multi-agent robot coordination framework (@tom_doerr) — потенциальный источник вдохновения для архитектуры coordination layer в AGIents.pro

### AISobolev Blog

- **Пост "MCP не умер — он в Uber"**: развернуть тезис @GergelyOrosz в полноценный разбор enterprise adoption MCP; высокий интерес аудитории (активная дискуссия)
- **Разбор Claude Code skills**: как community создаёт расширения — от Cloudflare scraping до drug discovery; показать механику и потенциал
- **"Plan mode везде"**: сравнительный пост Claude Code vs Gemini CLI vs другие tools по реализации planning capabilities
- **Критика AI productivity**: взять тезис @causalinf как отправную точку для честного разбора — когда AI agents реально помогают, а когда создают overhead

---

*Auto-generated by ai-daily-digest.sh*
*APIs: Grok API (X/Twitter) + Firecrawl Search (Reddit) + Claude SDK (synthesis)*
