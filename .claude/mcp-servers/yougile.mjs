#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js'
import fs from 'node:fs'
import path from 'node:path'

// Load .env file if exists
function loadEnvFile() {
  const envPaths = [
    path.join(process.cwd(), '.env'),
    path.join(process.cwd(), '..', '.env'),
  ]

  for (const envPath of envPaths) {
    try {
      const envContent = fs.readFileSync(envPath, 'utf-8')
      for (const line of envContent.split('\n')) {
        const trimmed = line.trim()
        if (trimmed && !trimmed.startsWith('#')) {
          const [key, ...valueParts] = trimmed.split('=')
          if (key && valueParts.length > 0) {
            const value = valueParts.join('=').replace(/^["']|["']$/g, '')
            if (!process.env[key]) {
              process.env[key] = value
            }
          }
        }
      }
      break
    } catch {
      // File doesn't exist, continue
    }
  }
}

loadEnvFile()

const API_BASE = 'https://yougile.com/api-v2'
const apiKey = process.env.YOUGILE_API_KEY

if (!apiKey) {
  console.error('YOUGILE_API_KEY environment variable is required')
  console.error('')
  console.error('To get your API key:')
  console.error('')
  console.error('1. First, get your company ID:')
  console.error(`   curl -X POST '${API_BASE}/auth/companies' \\`)
  console.error("     -H 'Content-Type: application/json' \\")
  console.error('     -d \'{"login": "your@email.com", "password": "your-password"}\'')
  console.error('')
  console.error('2. Then, get the API key using company ID:')
  console.error(`   curl -X POST '${API_BASE}/auth/keys' \\`)
  console.error("     -H 'Content-Type: application/json' \\")
  console.error('     -d \'{"login": "your@email.com", "password": "your-password", "companyId": "your-company-id"}\'')
  console.error('')
  console.error('3. Add the key to your .mcp.json file')
  console.error('')
  console.error('For detailed instructions, see YOUGILE_SETUP.md')
  process.exit(1)
}

// API helper function
async function yougileRequest(endpoint, method = 'GET', body = null) {
  const url = `${API_BASE}${endpoint}`
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
  }

  if (body) {
    options.body = JSON.stringify(body)
  }

  const response = await fetch(url, options)
  const data = await response.json()

  if (!response.ok) {
    throw new Error(data.error || `API error: ${response.status}`)
  }

  return data
}

// Tool handlers
async function listProjects() {
  const data = await yougileRequest('/projects')
  const projects = data.content || []

  if (projects.length === 0) {
    return 'No projects found'
  }

  return projects.map(p => `- ${p.title} (ID: ${p.id})`).join('\n')
}

async function listBoards(args) {
  const projectId = args.project_id
  if (!projectId) {
    throw new Error('project_id is required')
  }

  const data = await yougileRequest(`/boards?projectId=${projectId}`)
  const boards = data.content || []

  if (boards.length === 0) {
    return 'No boards found in this project'
  }

  return boards.map(b => `- ${b.title} (ID: ${b.id})`).join('\n')
}

async function listColumns(args) {
  const boardId = args.board_id
  if (!boardId) {
    throw new Error('board_id is required')
  }

  const data = await yougileRequest(`/columns?boardId=${boardId}`)
  const columns = data.content || []

  if (columns.length === 0) {
    return 'No columns found on this board'
  }

  return columns.map(c => `- ${c.title} (ID: ${c.id})`).join('\n')
}

async function listTasks(args) {
  const columnId = args.column_id
  if (!columnId) {
    throw new Error('column_id is required')
  }

  const limit = args.limit || 50
  const data = await yougileRequest(`/tasks?columnId=${columnId}&limit=${limit}`)
  const tasks = data.content || []

  if (tasks.length === 0) {
    return 'No tasks found in this column'
  }

  return tasks.map(t => {
    const completed = t.completed ? '[x]' : '[ ]'
    const deadline = t.deadline?.deadline ? ` (due: ${new Date(t.deadline.deadline).toLocaleDateString()})` : ''
    return `${completed} ${t.title}${deadline} (ID: ${t.id})`
  }).join('\n')
}

async function getTask(args) {
  const taskId = args.task_id
  if (!taskId) {
    throw new Error('task_id is required')
  }

  const task = await yougileRequest(`/tasks/${taskId}`)

  const lines = [
    `Title: ${task.title}`,
    `ID: ${task.id}`,
    `Completed: ${task.completed ? 'Yes' : 'No'}`,
  ]

  if (task.description) {
    lines.push(`Description: ${task.description}`)
  }

  if (task.deadline?.deadline) {
    lines.push(`Deadline: ${new Date(task.deadline.deadline).toLocaleDateString()}`)
  }

  if (task.assigned) {
    lines.push(`Assigned: ${Object.keys(task.assigned).length} users`)
  }

  if (task.checklists && task.checklists.length > 0) {
    lines.push('Checklists:')
    task.checklists.forEach(cl => {
      lines.push(`  ${cl.title}:`)
      cl.items?.forEach(item => {
        lines.push(`    ${item.completed ? '[x]' : '[ ]'} ${item.title}`)
      })
    })
  }

  return lines.join('\n')
}

async function createTask(args) {
  const columnId = args.column_id
  const title = args.title

  if (!columnId) {
    throw new Error('column_id is required')
  }
  if (!title) {
    throw new Error('title is required')
  }

  const body = {
    columnId,
    title,
  }

  if (args.description) {
    body.description = args.description
  }

  if (args.deadline) {
    body.deadline = {
      deadline: new Date(args.deadline).getTime(),
    }
  }

  if (args.assigned) {
    body.assigned = args.assigned
  }

  const result = await yougileRequest('/tasks', 'POST', body)

  return `Task created successfully!\nID: ${result.id}\nTitle: ${title}`
}

async function updateTask(args) {
  const taskId = args.task_id
  if (!taskId) {
    throw new Error('task_id is required')
  }

  const body = {}

  if (args.title !== undefined) {
    body.title = args.title
  }

  if (args.description !== undefined) {
    body.description = args.description
  }

  if (args.completed !== undefined) {
    body.completed = args.completed
  }

  if (args.deadline !== undefined) {
    body.deadline = args.deadline ? { deadline: new Date(args.deadline).getTime() } : null
  }

  if (Object.keys(body).length === 0) {
    throw new Error('At least one field to update is required')
  }

  await yougileRequest(`/tasks/${taskId}`, 'PUT', body)

  return `Task ${taskId} updated successfully!`
}

// Create MCP server
const server = new Server(
  { name: 'yougile', version: '1.0.0' },
  { capabilities: { tools: {} } },
)

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: 'list_projects',
      description: 'List all YouGile projects accessible to you',
      inputSchema: {
        type: 'object',
        properties: {},
        required: [],
      },
    },
    {
      name: 'list_boards',
      description: 'List all boards in a YouGile project',
      inputSchema: {
        type: 'object',
        properties: {
          project_id: {
            type: 'string',
            description: 'The ID of the project to list boards from',
          },
        },
        required: ['project_id'],
      },
    },
    {
      name: 'list_columns',
      description: 'List all columns on a YouGile board',
      inputSchema: {
        type: 'object',
        properties: {
          board_id: {
            type: 'string',
            description: 'The ID of the board to list columns from',
          },
        },
        required: ['board_id'],
      },
    },
    {
      name: 'list_tasks',
      description: 'List tasks in a YouGile column',
      inputSchema: {
        type: 'object',
        properties: {
          column_id: {
            type: 'string',
            description: 'The ID of the column to list tasks from',
          },
          limit: {
            type: 'number',
            description: 'Maximum number of tasks to return (default: 50)',
          },
        },
        required: ['column_id'],
      },
    },
    {
      name: 'get_task',
      description: 'Get detailed information about a specific YouGile task',
      inputSchema: {
        type: 'object',
        properties: {
          task_id: {
            type: 'string',
            description: 'The ID of the task to retrieve',
          },
        },
        required: ['task_id'],
      },
    },
    {
      name: 'create_task',
      description: 'Create a new task in a YouGile column',
      inputSchema: {
        type: 'object',
        properties: {
          column_id: {
            type: 'string',
            description: 'The ID of the column to create the task in',
          },
          title: {
            type: 'string',
            description: 'The title of the task',
          },
          description: {
            type: 'string',
            description: 'Optional description of the task',
          },
          deadline: {
            type: 'string',
            description: 'Optional deadline in ISO format (e.g., 2024-12-31)',
          },
          assigned: {
            type: 'object',
            description: 'Optional object mapping user IDs to roles',
          },
        },
        required: ['column_id', 'title'],
      },
    },
    {
      name: 'update_task',
      description: 'Update an existing YouGile task',
      inputSchema: {
        type: 'object',
        properties: {
          task_id: {
            type: 'string',
            description: 'The ID of the task to update',
          },
          title: {
            type: 'string',
            description: 'New title for the task',
          },
          description: {
            type: 'string',
            description: 'New description for the task',
          },
          completed: {
            type: 'boolean',
            description: 'Mark task as completed or not',
          },
          deadline: {
            type: 'string',
            description: 'New deadline in ISO format (e.g., 2024-12-31), or null to remove',
          },
        },
        required: ['task_id'],
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
      case 'list_projects':
        result = await listProjects()
        break
      case 'list_boards':
        result = await listBoards(args)
        break
      case 'list_columns':
        result = await listColumns(args)
        break
      case 'list_tasks':
        result = await listTasks(args)
        break
      case 'get_task':
        result = await getTask(args)
        break
      case 'create_task':
        result = await createTask(args)
        break
      case 'update_task':
        result = await updateTask(args)
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
  console.error('YouGile MCP Server running')
}

main().catch(console.error)
