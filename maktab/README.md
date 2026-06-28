# مکتب — Maktab

Islamic Research Workbench — an AI-powered research environment for
Hadith studies, Fiqh comparison, and manuscript work.

Built on [opencode](https://opencode.ai) with a custom browser frontend
and Tauri desktop packaging.

## Quick start (development)

```bash
# 1. Install dependencies
npm install

# 2. Install opencode globally
npm i -g opencode-ai@latest

# 3. Set your LLM API key
cp .env.example .env
# edit .env and add ANTHROPIC_API_KEY (or whichever provider)

# 4. Start opencode server + frontend together
npm run dev:all

# Browser opens at http://localhost:5173
```

## Project layout

```
maktab/
├── apps/
│   ├── web/              # Vite + React frontend (runs in browser / Tauri)
│   └── desktop/          # Tauri shell for Windows/macOS packaging
├── packages/
│   ├── mcp-hadith/       # MCP server — wraps your Hadith API
│   └── mcp-rijal/        # MCP server — wraps your Rijal/narrator API
└── .opencode/            # opencode config bundle (agents, rules, commands)
    ├── opencode.json
    ├── AGENTS.md
    ├── agents/
    ├── commands/
    └── skills/
```
