/**
 * Maktab — Hadith MCP Server
 *
 * Exposes three tools to the opencode agent:
 *   search_hadith   — full-text search across collections
 *   get_chain       — fetch isnad for a specific hadith ID
 *   grade_narrator  — get reliability data for a narrator
 *
 * Replace the stub API calls with your actual Hadith API.
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const API_BASE = process.env.HADITH_API_BASE_URL ?? "https://api.hadith.example.com";
const API_KEY  = process.env.HADITH_API_KEY ?? "";

async function apiGet(path: string, params: Record<string, string> = {}) {
  const url = new URL(`${API_BASE}${path}`);
  Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, v));
  const res = await fetch(url.toString(), {
    headers: { Authorization: `Bearer ${API_KEY}` },
  });
  if (!res.ok) throw new Error(`Hadith API error: ${res.status}`);
  return res.json();
}

const server = new Server(
  { name: "maktab-hadith", version: "0.1.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "search_hadith",
      description: "Search hadith collections by keyword, topic, or narrator name. Returns matching narrations with their collection, chapter, and grading.",
      inputSchema: {
        type: "object",
        properties: {
          query:      { type: "string", description: "Search terms (Arabic or English)" },
          collection: { type: "string", description: "Filter by collection: bukhari | muslim | tirmidhi | abudawud | nasai | ibnmajah | all", default: "all" },
          limit:      { type: "number", description: "Max results (default 10)", default: 10 },
        },
        required: ["query"],
      },
    },
    {
      name: "get_chain",
      description: "Retrieve the full isnad (chain of narrators) for a specific hadith by its database ID.",
      inputSchema: {
        type: "object",
        properties: {
          hadith_id:  { type: "string", description: "Hadith database ID" },
        },
        required: ["hadith_id"],
      },
    },
    {
      name: "grade_narrator",
      description: "Look up a narrator's reliability grade and biographical data from classical rijal works.",
      inputSchema: {
        type: "object",
        properties: {
          narrator_name: { type: "string", description: "Narrator name in Arabic or transliteration" },
        },
        required: ["narrator_name"],
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    if (name === "search_hadith") {
      const data = await apiGet("/v1/search", {
        q: String(args?.query ?? ""),
        collection: String(args?.collection ?? "all"),
        limit: String(args?.limit ?? 10),
      });
      return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
    }

    if (name === "get_chain") {
      const data = await apiGet(`/v1/hadith/${args?.hadith_id}/chain`);
      return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
    }

    if (name === "grade_narrator") {
      // Narrator grading is handled by the Rijal MCP server,
      // but this stub shows how you'd delegate if needed
      const data = await apiGet("/v1/rijal/search", {
        name: String(args?.narrator_name ?? ""),
      });
      return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
    }

    throw new Error(`Unknown tool: ${name}`);
  } catch (err) {
    return {
      content: [{ type: "text", text: `Error: ${String(err)}` }],
      isError: true,
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
console.error("[mcp-hadith] server running on stdio");
