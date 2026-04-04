#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js'

const API_URL = 'https://api.openai.com/v1/responses'
const MODEL = 'gpt-4o-mini'
const apiKey = process.env.OPENAI_API_KEY

if (!apiKey) {
  console.error('OPENAI_API_KEY environment variable is required')
  console.error('')
  console.error('To get your API key:')
  console.error('1. Go to https://platform.openai.com/api-keys')
  console.error('2. Create an API key')
  console.error('3. Add it to .mcp.json under "reddit-search" -> "env" -> "OPENAI_API_KEY"')
  process.exit(1)
}

// Call OpenAI API with web_search_preview tool
async function openaiRequest(prompt, searchContextSize = 'medium') {
  const response = await fetch(API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: MODEL,
      tools: [
        {
          type: 'web_search_preview',
          search_context_size: searchContextSize,
        },
      ],
      include: ['web_search_call.action.sources'],
      input: prompt,
    }),
  })

  if (!response.ok) {
    if (response.status === 401) {
      throw new Error('Invalid OPENAI_API_KEY — check your credentials at https://platform.openai.com/api-keys')
    }
    if (response.status === 429) {
      throw new Error('OpenAI API rate limit — try again in a minute')
    }
    throw new Error(`OpenAI API error: ${response.status} ${response.statusText}`)
  }

  return response.json()
}

// Extract text and citation URLs from OpenAI response
function parseOpenAIResponse(data) {
  const messages = (data.output ?? []).filter((o) => o.type === 'message')
  let text = ''
  const citations = []

  for (const msg of messages) {
    for (const block of msg.content ?? []) {
      if (block.type === 'output_text') {
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

// Tool: reddit_search — search Reddit by topic or subreddit
async function redditSearch(args) {
  const { query, subreddits, search_context_size } = args

  if (!query) {
    throw new Error('query is required')
  }

  // Build site filter
  let siteFilter = 'site:reddit.com'
  if (subreddits?.length) {
    siteFilter = subreddits
      .map((s) => `site:reddit.com/r/${s}`)
      .join(' OR ')
  }

  const prompt = `${siteFilter} ${query}

Search Reddit for the most upvoted and insightful discussions about ${query}.

For each discussion include:
- Subreddit name (r/...)
- Post title
- Summary of the post and top comments
- Key practical advice or consensus
- Link to the post

Focus on practical advice, real experiences, and highly upvoted responses.
Provide links to the most important posts.`

  const data = await openaiRequest(prompt, search_context_size ?? 'medium')
  const { text, citations } = parseOpenAIResponse(data)

  const parts = [`## Reddit Search: ${query}`, '']

  if (subreddits?.length) {
    parts.push(`**Subreddits:** ${subreddits.map((s) => `r/${s}`).join(', ')}`, '')
  }

  parts.push(text)

  if (citations.length > 0) {
    parts.push('', '### Sources', ...citations.map((url) => `- ${url}`))
  }

  return parts.join('\n')
}

// Tool: reddit_get_post — get a specific Reddit post by URL
async function redditGetPost(args) {
  const { url } = args

  if (!url) {
    throw new Error('url is required')
  }

  const prompt = `${url}

Find and describe this specific Reddit post.

Please provide:
- Subreddit (r/...)
- Post title and author
- Full post content or detailed summary
- Top 3-5 comments with the most upvotes
- Community consensus or key takeaways
- Any notable disagreements in the comments`

  const data = await openaiRequest(prompt, 'high')
  const { text, citations } = parseOpenAIResponse(data)

  const parts = [`## Reddit Post: ${url}`, '', text]

  if (citations.length > 0) {
    parts.push('', '### References', ...citations.map((u) => `- ${u}`))
  }

  return parts.join('\n')
}

// Create MCP server
const server = new Server(
  { name: 'reddit-search', version: '1.0.0' },
  { capabilities: { tools: {} } },
)

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: 'reddit_search',
      description:
        'Search Reddit discussions via OpenAI web search. Returns AI-synthesized summary with citations.',
      inputSchema: {
        type: 'object',
        properties: {
          query: {
            type: 'string',
            description: 'Search topic or keywords',
          },
          subreddits: {
            type: 'array',
            items: { type: 'string' },
            description:
              'Restrict search to specific subreddits (e.g. ["artificial", "MachineLearning"]). Without r/ prefix.',
          },
          search_context_size: {
            type: 'string',
            enum: ['low', 'medium', 'high'],
            description:
              'Search depth: low (faster/cheaper), medium (default), high (more thorough)',
          },
        },
        required: ['query'],
      },
    },
    {
      name: 'reddit_get_post',
      description:
        'Get details of a specific Reddit post by URL. Returns content, top comments, and community consensus.',
      inputSchema: {
        type: 'object',
        properties: {
          url: {
            type: 'string',
            description:
              'Full Reddit post URL (e.g. https://www.reddit.com/r/subreddit/comments/...)',
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
      case 'reddit_search':
        result = await redditSearch(args)
        break
      case 'reddit_get_post':
        result = await redditGetPost(args)
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
  console.error('Reddit-Search MCP Server running')
}

main().catch(console.error)
