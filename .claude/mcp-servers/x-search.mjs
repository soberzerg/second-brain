#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js'

const API_URL = 'https://api.x.ai/v1/responses'
const MODEL = 'grok-4-1-fast'
const apiKey = process.env.XAI_API_KEY

if (!apiKey) {
  console.error('XAI_API_KEY environment variable is required')
  console.error('')
  console.error('To get your API key:')
  console.error('1. Go to https://console.x.ai/')
  console.error('2. Create an API key')
  console.error('3. Add it to .mcp.json under "x-search" -> "env" -> "XAI_API_KEY"')
  process.exit(1)
}

// Compute default date range (last 7 days)
function getDefaultDates() {
  const to = new Date()
  const from = new Date(to)
  from.setDate(from.getDate() - 7)
  return {
    from_date: from.toISOString().slice(0, 10),
    to_date: to.toISOString().slice(0, 10),
  }
}

// Call Grok API with x_search tool
async function grokRequest(prompt, xSearchParams = {}) {
  const response = await fetch(API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: MODEL,
      tools: [{ type: 'x_search', x_search: xSearchParams }],
      input: [{ role: 'user', content: prompt }],
    }),
  })

  if (!response.ok) {
    if (response.status === 401) {
      throw new Error('Invalid XAI_API_KEY — check your credentials at https://console.x.ai/')
    }
    if (response.status === 429) {
      throw new Error('Grok API rate limit — try again in a minute')
    }
    throw new Error(`Grok API error: ${response.status} ${response.statusText}`)
  }

  return response.json()
}

// Extract text and citation URLs from Grok response
function parseGrokResponse(data) {
  const messages = (data.output ?? []).filter((o) => o.type === 'message')
  let text = ''
  const citations = []

  for (const msg of messages) {
    for (const block of msg.content ?? []) {
      if (block.type === 'text') {
        text += block.text
        for (const ann of block.annotations ?? []) {
          if (ann.type === 'url_citation' && ann.url) {
            citations.push(ann.url)
          }
        }
      }
    }
  }

  return { text, citations }
}

// Tool: x_search — search X/Twitter by topic or handles
async function xSearch(args) {
  const { query, from_date, to_date, allowed_handles, excluded_handles } = args

  if (!query) {
    throw new Error('query is required')
  }

  const defaults = getDefaultDates()
  const xSearchParams = {
    from_date: from_date ?? defaults.from_date,
    to_date: to_date ?? defaults.to_date,
  }

  if (allowed_handles?.length) {
    if (allowed_handles.length > 10) {
      throw new Error('allowed_handles supports max 10 accounts')
    }
    xSearchParams.allowed_x_handles = allowed_handles
  }

  if (excluded_handles?.length) {
    if (excluded_handles.length > 10) {
      throw new Error('excluded_handles supports max 10 accounts')
    }
    xSearchParams.excluded_x_handles = excluded_handles
  }

  const prompt = `Search X/Twitter for posts about: ${query}

For each notable post include:
- Author handle (@username)
- Key quote or summary of the post
- Why it's notable (engagement, expertise, unique perspective)

Focus on expert opinions and substantial discussions, not promotional content.
Provide links to the most important posts.`

  const data = await grokRequest(prompt, xSearchParams)
  const { text, citations } = parseGrokResponse(data)

  const parts = [
    `## X/Twitter Search: ${query}`,
    `**Period:** ${xSearchParams.from_date} — ${xSearchParams.to_date}`,
    '',
    text,
  ]

  if (citations.length > 0) {
    parts.push('', '### Sources', ...citations.map((url) => `- ${url}`))
  }

  return parts.join('\n')
}

// Tool: x_get_post — get a specific post by URL
async function xGetPost(args) {
  const { url } = args

  if (!url) {
    throw new Error('url is required')
  }

  const today = new Date()
  const ninetyDaysAgo = new Date(today)
  ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90)

  const xSearchParams = {
    from_date: ninetyDaysAgo.toISOString().slice(0, 10),
    to_date: today.toISOString().slice(0, 10),
  }

  // Extract handle from URL to narrow search
  const handleMatch = url.match(/(?:twitter|x)\.com\/([^/]+)\/status/)
  if (handleMatch) {
    xSearchParams.allowed_x_handles = [handleMatch[1]]
  }

  const prompt = `Find and describe this specific X/Twitter post: ${url}

Please provide:
- Author name and handle (@username)
- Full post content or close paraphrase
- Date posted
- Engagement metrics if available (likes, retweets, replies)
- Any notable replies or quote tweets
- Context about why this post is significant`

  const data = await grokRequest(prompt, xSearchParams)
  const { text, citations } = parseGrokResponse(data)

  const parts = [`## X Post: ${url}`, '', text]

  if (citations.length > 0) {
    parts.push('', '### References', ...citations.map((u) => `- ${u}`))
  }

  return parts.join('\n')
}

// Create MCP server
const server = new Server(
  { name: 'x-search', version: '1.0.0' },
  { capabilities: { tools: {} } },
)

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: 'x_search',
      description:
        'Search X/Twitter posts via Grok API. Returns AI-synthesized summary with citations.',
      inputSchema: {
        type: 'object',
        properties: {
          query: {
            type: 'string',
            description: 'Search topic or keywords',
          },
          from_date: {
            type: 'string',
            description:
              'Start date in YYYY-MM-DD format (default: 7 days ago)',
          },
          to_date: {
            type: 'string',
            description: 'End date in YYYY-MM-DD format (default: today)',
          },
          allowed_handles: {
            type: 'array',
            items: { type: 'string' },
            description:
              'Only search posts from these X handles (max 10). Without @ prefix.',
          },
          excluded_handles: {
            type: 'array',
            items: { type: 'string' },
            description:
              'Exclude posts from these X handles (max 10). Without @ prefix.',
          },
        },
        required: ['query'],
      },
    },
    {
      name: 'x_get_post',
      description:
        'Get details of a specific X/Twitter post by URL. Returns content, author, engagement info.',
      inputSchema: {
        type: 'object',
        properties: {
          url: {
            type: 'string',
            description:
              'Full X/Twitter post URL (e.g. https://x.com/username/status/123456)',
          },
        },
        required: ['url'],
      },
    },
  ],
}))

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { arguments: args, name } = request.params

  try {
    let result
    switch (name) {
      case 'x_search':
        result = await xSearch(args)
        break
      case 'x_get_post':
        result = await xGetPost(args)
        break
      default:
        throw new Error(`Unknown tool: ${name}`)
    }

    return {
      content: [{ text: result, type: 'text' }],
    }
  } catch (error) {
    throw new Error(`Tool execution failed: ${error.message}`)
  }
})

// Start server
async function main() {
  const transport = new StdioServerTransport()
  await server.connect(transport)
  console.error('X-Search MCP Server running')
}

main().catch(console.error)
