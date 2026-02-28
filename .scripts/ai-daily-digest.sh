#!/bin/bash
# AI Daily Digest — automated daily AI news collection from X/Twitter and Reddit
# Uses Grok API (X), OpenAI API (Reddit), and Anthropic API (synthesis)
#
# Usage:
#   .scripts/ai-daily-digest.sh              # run normally
#   .scripts/ai-daily-digest.sh --force      # overwrite existing digest
#   .scripts/ai-daily-digest.sh --no-claude  # skip Claude synthesis, save raw
#   .scripts/ai-daily-digest.sh --dry-run    # show config, don't execute
#
# Requires: XAI_API_KEY, OPENAI_API_KEY (for data), ANTHROPIC_API_KEY (for synthesis)
# Install: jq, curl

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$VAULT_DIR/03_Resources/AI Daily Digest"
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="$OUTPUT_DIR/$DATE - AI Daily Digest.md"
TOPICS_FILE="$SCRIPT_DIR/ai-daily-digest-topics.txt"
LOG_FILE="$SCRIPT_DIR/.ai-digest.log"
FROM_DATE=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)
TO_DATE="$DATE"
USE_CLAUDE=true
FORCE=false
DRY_RUN=false

# --- Source API keys ---
if [ -f "$HOME/.env.ai-digest" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.env.ai-digest"
elif [ -f "$VAULT_DIR/.env" ]; then
    # shellcheck source=/dev/null
    source "$VAULT_DIR/.env"
fi

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-claude)  USE_CLAUDE=false; shift ;;
        --force)      FORCE=true; shift ;;
        --dry-run)    DRY_RUN=true; shift ;;
        *)            echo "Unknown option: $1"; exit 1 ;;
    esac
done

# --- Logging helper ---
log() {
    local level="$1"
    shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $*" | tee -a "$LOG_FILE"
}

log "INFO" "Starting AI Daily Digest for $DATE"

# --- Idempotency check ---
if [ -f "$OUTPUT_FILE" ] && [ "$FORCE" != true ]; then
    log "INFO" "Digest already exists for $DATE. Use --force to overwrite."
    exit 0
fi

# --- Validate prerequisites ---
if ! command -v jq &>/dev/null; then
    log "ERROR" "jq is required but not installed. Run: brew install jq"
    exit 1
fi

if ! command -v curl &>/dev/null; then
    log "ERROR" "curl is required but not installed."
    exit 1
fi

HAS_X=true
HAS_REDDIT=true

if [ -z "${XAI_API_KEY:-}" ]; then
    log "WARN" "XAI_API_KEY not set — skipping X/Twitter"
    HAS_X=false
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
    log "WARN" "OPENAI_API_KEY not set — skipping Reddit"
    HAS_REDDIT=false
fi

if [ "$HAS_X" = false ] && [ "$HAS_REDDIT" = false ]; then
    log "ERROR" "No API keys available. Set XAI_API_KEY and/or OPENAI_API_KEY."
    exit 1
fi

# --- Load topics ---
if [ ! -f "$TOPICS_FILE" ]; then
    log "ERROR" "Topics file not found: $TOPICS_FILE"
    exit 1
fi

TOPICS=""
while IFS= read -r line; do
    [ -z "$line" ] && continue
    TOPICS="${TOPICS}${TOPICS:+, }$line"
done < "$TOPICS_FILE"

log "INFO" "Topics: $TOPICS"
log "INFO" "Period: $FROM_DATE — $TO_DATE"

# --- Dry run ---
if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "=== DRY RUN ==="
    echo "Date:       $DATE"
    echo "Period:     $FROM_DATE — $TO_DATE"
    echo "Topics:     $TOPICS"
    echo "Output:     $OUTPUT_FILE"
    echo "X/Twitter:  $([ "$HAS_X" = true ] && echo 'YES' || echo 'NO (no XAI_API_KEY)')"
    echo "Reddit:     $([ "$HAS_REDDIT" = true ] && echo 'YES' || echo 'NO (no OPENAI_API_KEY)')"
    echo "Claude:     $([ "$USE_CLAUDE" = true ] && command -v claude &>/dev/null && echo 'YES' || echo 'NO')"
    echo "==============="
    exit 0
fi

# --- Create output directory ---
mkdir -p "$OUTPUT_DIR"

# --- Build search prompts ---
X_PROMPT="Search X/Twitter for the most important AI news and discussions from $FROM_DATE to $TO_DATE on these topics: $TOPICS.

For each notable finding include:
- Author handle (@username)
- Key quote or summary
- Why it's notable (engagement, expertise, unique perspective)

Focus on expert opinions, practitioners, and substantial discussions. Not promotional content.
Summarize in Russian. Keep technical terms in English.
Provide links to the most important posts."

REDDIT_PROMPT="site:reddit.com $TOPICS

Find the most discussed Reddit posts from $FROM_DATE to $TO_DATE about AI technology, AI agents, coding with AI, and AI business automation.

For each discussion include:
- Subreddit name (r/...)
- Post title and link
- Summary of the discussion and top comments
- Key practical takeaways

Focus on practical insights, real experiences, and community consensus.
Summarize in Russian. Keep technical terms in English."

# --- Phase 1: X/Twitter via Grok API ---
X_RESULTS=""
X_URLS=""

if [ "$HAS_X" = true ]; then
    log "INFO" "Fetching X/Twitter via Grok API..."

    X_RAW=$(curl -s -X POST "https://api.x.ai/v1/responses" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $XAI_API_KEY" \
        --max-time 60 \
        -d "$(jq -n \
            --arg prompt "$X_PROMPT" \
            --arg from "$FROM_DATE" \
            --arg to "$TO_DATE" \
            '{
                model: "grok-4-1-fast",
                tools: [{
                    type: "x_search",
                    x_search: {
                        from_date: $from,
                        to_date: $to
                    }
                }],
                input: [{role: "user", content: $prompt}]
            }')" 2>/dev/null) || true

    if [ -n "$X_RAW" ]; then
        # Check for API error
        API_ERROR=$(echo "$X_RAW" | jq -r '.error // empty' 2>/dev/null) || true
        if [ -n "$API_ERROR" ]; then
            log "WARN" "X/Twitter API error: $API_ERROR"
            HAS_X=false
        else
            X_RESULTS=$(echo "$X_RAW" | jq -r '.output[] | select(.type == "message") | .content[] | select(.type == "text") | .text' 2>/dev/null) || true
            X_URLS=$(echo "$X_RAW" | jq -r '.output[] | select(.type == "message") | .content[] | select(.type == "text") | .annotations[]? | select(.type == "url_citation") | .url' 2>/dev/null) || true

            if [ -n "$X_RESULTS" ]; then
                log "INFO" "X/Twitter: Success (${#X_RESULTS} chars)"
            else
                log "WARN" "X/Twitter: Empty results"
                HAS_X=false
            fi
        fi
    else
        log "WARN" "X/Twitter: No response (timeout or network error)"
        HAS_X=false
    fi
fi

# --- Phase 2: Reddit via OpenAI API ---
REDDIT_RESULTS=""
REDDIT_URLS=""

if [ "$HAS_REDDIT" = true ]; then
    log "INFO" "Fetching Reddit via OpenAI API..."

    REDDIT_RAW=$(curl -s -X POST "https://api.openai.com/v1/responses" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        --max-time 60 \
        -d "$(jq -n \
            --arg prompt "$REDDIT_PROMPT" \
            '{
                model: "gpt-4o-mini",
                tools: [{
                    type: "web_search_preview",
                    search_context_size: "medium"
                }],
                include: ["web_search_call.action.sources"],
                input: $prompt
            }')" 2>/dev/null) || true

    if [ -n "$REDDIT_RAW" ]; then
        API_ERROR=$(echo "$REDDIT_RAW" | jq -r '.error.message // empty' 2>/dev/null) || true
        if [ -n "$API_ERROR" ]; then
            log "WARN" "Reddit API error: $API_ERROR"
            HAS_REDDIT=false
        else
            REDDIT_RESULTS=$(echo "$REDDIT_RAW" | jq -r '.output[] | select(.type == "message") | .content[] | select(.type == "output_text") | .text' 2>/dev/null) || true
            REDDIT_URLS=$(echo "$REDDIT_RAW" | jq -r '.output[] | select(.type == "message") | .content[] | .annotations[]? | select(.type == "url_citation") | .url' 2>/dev/null) || true

            if [ -n "$REDDIT_RESULTS" ]; then
                log "INFO" "Reddit: Success (${#REDDIT_RESULTS} chars)"
            else
                log "WARN" "Reddit: Empty results"
                HAS_REDDIT=false
            fi
        fi
    else
        log "WARN" "Reddit: No response (timeout or network error)"
        HAS_REDDIT=false
    fi
fi

# --- Check we have at least some data ---
if [ "$HAS_X" = false ] && [ "$HAS_REDDIT" = false ]; then
    log "ERROR" "Both APIs returned no data. Aborting."
    exit 1
fi

# --- Phase 3: Synthesis via Claude SDK ---
DIGEST_BODY=""

if [ "$USE_CLAUDE" = true ] && command -v claude &>/dev/null; then
    log "INFO" "Synthesizing with Claude SDK..."

    SYNTHESIS_PROMPT="Ты создаёшь ежедневный AI-дайджест для Obsidian vault.

Вот сырые результаты исследования за $FROM_DATE — $TO_DATE:

=== X/TWITTER ===
${X_RESULTS:-Данные недоступны}

=== REDDIT ===
${REDDIT_RESULTS:-Данные недоступны}

=== URL ИСТОЧНИКИ X ===
${X_URLS:-Нет}

=== URL ИСТОЧНИКИ REDDIT ===
${REDDIT_URLS:-Нет}

Создай структурированный дайджест на русском (технические термины на English) в таком формате:

## Top Stories

Выдели 3-5 главных новостей/трендов дня. Для каждой:
### N. [Заголовок]
**Источник:** X / Reddit | **Ссылка:** [url если есть]
[2-3 предложения описания]

## X/Twitter Highlights

Ключевые посты и мнения экспертов. Указывай @handles и ссылки.

## Reddit Discussions

Ключевые обсуждения. Указывай r/subreddit и ссылки.

## Тренды дня

Буллет-лист из 3-5 трендов.

## Релевантность для проектов

### AGIents.pro
- [как сегодняшние новости относятся к платформе AI-агентов]

### AISobolev Blog
- [идеи для контента на основе сегодняшних новостей]

НЕ добавляй frontmatter, заголовок h1 или disclaimer — они будут добавлены скриптом.
Пиши только контент дайджеста начиная с ## Top Stories."

    DIGEST_BODY=$(echo "$SYNTHESIS_PROMPT" | claude -p --model sonnet --no-session-persistence 2>/dev/null) || true

    if [ -n "$DIGEST_BODY" ]; then
        log "INFO" "Claude synthesis: Success (${#DIGEST_BODY} chars)"
    else
        log "WARN" "Claude synthesis failed, falling back to raw output"
        USE_CLAUDE=false
    fi
fi

# --- Fallback: raw output without Claude synthesis ---
if [ -z "$DIGEST_BODY" ]; then
    log "INFO" "Using raw output (no Claude synthesis)"
    DIGEST_BODY=""

    if [ "$HAS_X" = true ] && [ -n "$X_RESULTS" ]; then
        DIGEST_BODY+="## X/Twitter Highlights

$X_RESULTS

### Источники X
"
        if [ -n "$X_URLS" ]; then
            while IFS= read -r url; do
                DIGEST_BODY+="- $url
"
            done <<< "$X_URLS"
        fi
        DIGEST_BODY+="
---

"
    fi

    if [ "$HAS_REDDIT" = true ] && [ -n "$REDDIT_RESULTS" ]; then
        DIGEST_BODY+="## Reddit Discussions

$REDDIT_RESULTS

### Источники Reddit
"
        if [ -n "$REDDIT_URLS" ]; then
            while IFS= read -r url; do
                DIGEST_BODY+="- $url
"
            done <<< "$REDDIT_URLS"
        fi
    fi
fi

# --- Phase 4: Build and save the file ---
PLATFORMS=""
[ "$HAS_X" = true ] && PLATFORMS="X/Twitter"
if [ "$HAS_REDDIT" = true ]; then
    [ -n "$PLATFORMS" ] && PLATFORMS="$PLATFORMS, "
    PLATFORMS="${PLATFORMS}Reddit"
fi

cat > "$OUTPUT_FILE" << HEREDOC
---
type: ai-daily-digest
date: $DATE
platforms: [$PLATFORMS]
period: $FROM_DATE — $TO_DATE
status: completed
tags: [daily-digest, ai-news, auto-generated]
---

# AI Daily Digest — $DATE

**Период:** $FROM_DATE — $TO_DATE
**Платформы:** $PLATFORMS

> AI-синтезированный анализ через Grok API (X/Twitter) + OpenAI API (Reddit)$([ "$USE_CLAUDE" = true ] && echo " + Claude (синтез)")

---

$DIGEST_BODY

---

*Auto-generated by ai-daily-digest.sh*
*APIs: Grok API (X/Twitter) + OpenAI web_search (Reddit)$([ "$USE_CLAUDE" = true ] && echo " + Claude SDK (synthesis)")*
HEREDOC

log "INFO" "Digest saved: $OUTPUT_FILE"
echo "Done! Digest saved to: $OUTPUT_FILE"
