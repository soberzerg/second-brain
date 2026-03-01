#!/bin/bash
# AI Daily Digest — automated daily AI news collection from X/Twitter and Reddit
# Uses Grok API (X), Firecrawl API (Reddit), and Anthropic API (synthesis)
#
# Usage:
#   .scripts/ai-daily-digest.sh              # run normally
#   .scripts/ai-daily-digest.sh --force      # overwrite existing digest
#   .scripts/ai-daily-digest.sh --no-claude  # skip Claude synthesis, save raw
#   .scripts/ai-daily-digest.sh --dry-run    # show config, don't execute
#
# Requires: XAI_API_KEY, FIRECRAWL_API_KEY (for data), ANTHROPIC_API_KEY (for synthesis)
# Install: jq, curl

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$VAULT_DIR/500_Research/510_AI_Daily_Digest"
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

if [ -z "${FIRECRAWL_API_KEY:-}" ]; then
    log "WARN" "FIRECRAWL_API_KEY not set — skipping Reddit"
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
    echo "Reddit:     $([ "$HAS_REDDIT" = true ] && echo 'YES' || echo 'NO (no FIRECRAWL_API_KEY)')"
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

# Reddit search queries are defined inline in Phase 2 (Firecrawl)

# --- Phase 1: X/Twitter via Grok API (python3 for Unicode safety) ---
X_RESULTS=""
X_URLS=""

if [ "$HAS_X" = true ]; then
    log "INFO" "Fetching X/Twitter via Grok API..."

    export FROM_DATE TO_DATE
    X_PARSED=$(python3 -c "
import json, urllib.request, sys, os

api_key = os.environ.get('XAI_API_KEY', '')
prompt = sys.stdin.read()
from_date = os.environ.get('FROM_DATE', '')
to_date = os.environ.get('TO_DATE', '')

payload = {
    'model': 'grok-4-1-fast',
    'tools': [{
        'type': 'x_search',
        'x_search': {
            'from_date': from_date,
            'to_date': to_date
        }
    }],
    'input': [{'role': 'user', 'content': prompt}]
}

req = urllib.request.Request(
    'https://api.x.ai/v1/responses',
    data=json.dumps(payload).encode('utf-8'),
    headers={
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {api_key}'
    },
    method='POST'
)

try:
    with urllib.request.urlopen(req, timeout=90) as resp:
        data = json.loads(resp.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    body = e.read().decode('utf-8', errors='replace')
    print(f'ERROR:{body[:200]}')
    sys.exit(0)
except Exception as e:
    print(f'ERROR:{e}')
    sys.exit(0)

# Check for API error
api_error = data.get('error')
if api_error:
    print(f'ERROR:{api_error}')
    sys.exit(0)

text_parts = []
urls = []
for item in data.get('output', []):
    if item.get('type') == 'message':
        for content in item.get('content', []):
            if content.get('type') == 'text':
                text_parts.append(content.get('text', ''))
                for ann in content.get('annotations', []):
                    if ann.get('type') == 'url_citation':
                        urls.append(ann.get('url', ''))

text = '\n'.join(text_parts)
if text:
    print(f'TEXT:{text}')
    if urls:
        print(f'URLS:{chr(10).join(urls)}')
else:
    print('ERROR:Empty results')
" <<< "$X_PROMPT" 2>/dev/null) || true

    if [[ "$X_PARSED" == ERROR:* ]]; then
        log "WARN" "X/Twitter API: ${X_PARSED#ERROR:}"
        HAS_X=false
    elif [[ "$X_PARSED" == TEXT:* ]]; then
        X_RESULTS="${X_PARSED#TEXT:}"
        if [[ "$X_RESULTS" == *"URLS:"* ]]; then
            X_URLS="${X_RESULTS#*URLS:}"
            X_RESULTS="${X_RESULTS%%URLS:*}"
        fi
        log "INFO" "X/Twitter: Success (${#X_RESULTS} chars)"
    else
        log "WARN" "X/Twitter: Empty or unexpected response"
        HAS_X=false
    fi
fi

# --- Phase 2: Reddit via Firecrawl Search API ---
REDDIT_RESULTS=""
REDDIT_URLS=""

if [ "$HAS_REDDIT" = true ]; then
    log "INFO" "Fetching Reddit via Firecrawl Search API..."

    # Read topics into array for per-topic search
    SEARCH_QUERIES=(
        "AI agents multi-agent systems site:reddit.com"
        "Claude Code Cursor AI coding tools site:reddit.com"
        "GPT Claude Gemini AI model update site:reddit.com"
        "MCP protocol model context protocol site:reddit.com"
        "AI startup solopreneur site:reddit.com"
        "AI business automation site:reddit.com"
    )

    REDDIT_PARSED=$(python3 -c "
import json, urllib.request, sys, os

api_key = os.environ.get('FIRECRAWL_API_KEY', '')
queries = json.loads(sys.stdin.read())

all_results = []
seen_urls = set()

for query in queries:
    payload = {
        'query': query,
        'limit': 5,
        'scrapeOptions': {
            'formats': ['markdown'],
            'onlyMainContent': True
        }
    }

    req = urllib.request.Request(
        'https://api.firecrawl.dev/v1/search',
        data=json.dumps(payload).encode('utf-8'),
        headers={
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {api_key}'
        },
        method='POST'
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode('utf-8'))

        for item in data.get('data', []):
            url = item.get('url', '')
            if url in seen_urls:
                continue
            if '/r/' not in url or 'developers.reddit.com' in url:
                continue
            seen_urls.add(url)
            all_results.append({
                'url': url,
                'title': item.get('title', '').replace(' - Reddit', '').replace(' : r/', ' | r/'),
                'description': item.get('description', ''),
                'markdown': (item.get('markdown', '') or '')[:500]
            })
    except Exception:
        continue

if not all_results:
    print('ERROR:No Reddit posts found via Firecrawl')
    sys.exit(0)

lines = []
urls_list = []
for r in all_results[:15]:
    lines.append(f'### {r[\"title\"]}')
    lines.append(f'**Link:** {r[\"url\"]}')
    if r['description']:
        lines.append(f'{r[\"description\"]}')
    if r['markdown']:
        # Take first meaningful paragraph
        for para in r['markdown'].split(chr(10)*2):
            para = para.strip()
            if len(para) > 50 and not para.startswith('#') and not para.startswith('['):
                lines.append(f'> {para[:300]}')
                break
    lines.append('')
    urls_list.append(r['url'])

print('TEXT:' + chr(10).join(lines))
if urls_list:
    print('URLS:' + chr(10).join(urls_list))
" <<< "$(printf '%s\n' "${SEARCH_QUERIES[@]}" | jq -R . | jq -s .)" 2>/dev/null) || true

    if [[ "$REDDIT_PARSED" == ERROR:* ]]; then
        log "WARN" "Reddit: ${REDDIT_PARSED#ERROR:}"
        HAS_REDDIT=false
    elif [[ "$REDDIT_PARSED" == TEXT:* ]]; then
        REDDIT_RESULTS="${REDDIT_PARSED#TEXT:}"
        if [[ "$REDDIT_RESULTS" == *"URLS:"* ]]; then
            REDDIT_URLS="${REDDIT_RESULTS#*URLS:}"
            REDDIT_RESULTS="${REDDIT_RESULTS%%URLS:*}"
        fi
        log "INFO" "Reddit: Success (${#REDDIT_RESULTS} chars)"
    else
        log "WARN" "Reddit: Unexpected response"
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

> AI-синтезированный анализ через Grok API (X/Twitter) + Firecrawl API (Reddit)$([ "$USE_CLAUDE" = true ] && echo " + Claude (синтез)")

---

$DIGEST_BODY

---

*Auto-generated by ai-daily-digest.sh*
*APIs: Grok API (X/Twitter) + Firecrawl Search (Reddit)$([ "$USE_CLAUDE" = true ] && echo " + Claude SDK (synthesis)")*
HEREDOC

log "INFO" "Digest saved: $OUTPUT_FILE"
echo "Done! Digest saved to: $OUTPUT_FILE"
