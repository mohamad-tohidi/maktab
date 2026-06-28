/**
 * Maktab — Hadith MCP Server
 *
 * Exposes three tools to the opencode agent:
 *   search_hadith   — full-text search across collections
 *   get_chain       — fetch isnad for a specific hadith ID
 *   grade_narrator  — get reliability data for a narrator
 *
 * MOCK IMPLEMENTATION for development.
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

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
      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            results: [
              {
                id: "1",
                collection: "bukhari",
                text: "MOCK: Innamal a'malu binniyat...",
                chapter: "Book of Intentions",
                grading: "Sahih"
              },
              {
                id: "2",
                collection: "muslim",
                text: "MOCK: The Prophet (ﷺ) said...",
                chapter: "Book of Faith",
                grading: "Sahih"
              }
            ],
            count: 2
          }, null, 2)
        }]
      };
    }

    if (name === "get_chain") {
      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            hadith_id: args?.hadith_id,
            chain: ["Imam Bukhari", "Malik", "Nafi'", "Ibn Umar"]
          }, null, 2)
        }]
      };
    }

    if (name === "grade_narrator") {
      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            narrator_name: args?.narrator_name,
            grade: "Thiqah (Reliable)",
            era: "Tabi'un"
          }, null, 2)
        }]
      };
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
console.error("[mcp-hadith] server running on stdio (MOCK MODE)");
