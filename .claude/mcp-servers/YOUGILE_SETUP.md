# YouGile MCP Server - Setup Guide

## Step 1: Get Your Company ID

First, get the list of companies associated with your YouGile account:

```bash
curl -X POST 'https://yougile.com/api-v2/auth/companies' \
  -H 'Content-Type: application/json' \
  -d '{
    "login": "your@email.com",
    "password": "your-password"
  }'
```

Response example:

```json
{
  "content": [
    {
      "id": "44eccf40-a027-4d06-b5c2-18f4c02bb026",
      "name": "My Company"
    }
  ]
}
```

Save the `id` value for the next step.

## Step 2: Get Your API Key

Use your company ID to generate an API key:

```bash
curl -X POST 'https://yougile.com/api-v2/auth/keys' \
  -H 'Content-Type: application/json' \
  -d '{
    "login": "your@email.com",
    "password": "your-password",
    "companyId": "44eccf40-a027-4d06-b5c2-18f4c02bb026"
  }'
```

Response example:

```json
{
  "key": "-VRKgqzejQhROjMTmOk3h20Rnj6XKkwBFx5GkK1fA34TvLFmiVdmEPt3-ygeWfiy"
}
```

Save the `key` value.

## Step 3: Configure .mcp.json

Add the YouGile configuration to your `.mcp.json` file:

```json
{
  "mcpServers": {
    "yougile": {
      "type": "stdio",
      "command": "node",
      "args": [".claude/mcp-servers/yougile.mjs"],
      "env": {
        "YOUGILE_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

Replace `your-api-key-here` with the key from Step 2.

## Step 4: Restart Claude Code

Close and reopen Claude Code to load the new MCP server.

## Step 5: Verify Installation

In Claude Code, type `/mcp` to see connected servers. You should see:

```
yougile: connected
```

## Available Tools

Once configured, the following tools are available:

| Tool | Description |
|------|-------------|
| `list_projects` | List all accessible projects |
| `list_boards` | List boards in a project |
| `list_columns` | List columns on a board |
| `list_tasks` | List tasks in a column |
| `get_task` | Get task details |
| `create_task` | Create a new task |
| `update_task` | Update an existing task |

## Usage Examples

### View Projects

```
Use mcp__yougile__list_projects to show my projects
```

### View Tasks in a Column

```
Use mcp__yougile__list_tasks with column_id "abc123"
```

### Create a Task

```
Use mcp__yougile__create_task to create a task titled "Review PR" in column "xyz789"
```

## Troubleshooting

### Server Not Connecting

1. Check that the API key is correct in `.mcp.json`
2. Verify the key works by running:

   ```bash
   curl -H "Authorization: Bearer YOUR_KEY" https://yougile.com/api-v2/projects
   ```

3. Test the server directly:

   ```bash
   YOUGILE_API_KEY="your-key" node .claude/mcp-servers/yougile.mjs
   ```

### API Rate Limits

YouGile API has a limit of 50 requests per minute per company.

## API Documentation

Full API documentation: https://ru.yougile.com/api-v2
