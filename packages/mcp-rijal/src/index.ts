/**
 * Maktab — Rijal MCP Server
 *
 * Exposes narrator validation and biography tools.
 *   lookup_narrator  — find narrator by name, get bio + grades
 *   validate_chain   — assess a full isnad as an array of names
 *   get_biography    — detailed biography from classical rijal works
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
  { name: "maktab-rijal", version: "0.1.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "lookup_narrator",
      description: "Find a hadith narrator by name and return their reliability grade, era, teachers, and students.",
      inputSchema: {
        type: "object",
        properties: {
          name: { type: "string", description: "Narrator name (Arabic or transliteration)" },
        },
        required: ["name"],
      },
    },
    {
      name: "validate_chain",
      description: "Validate a complete isnad by checking each narrator's reliability and the continuity of the chain.",
      inputSchema: {
        type: "object",
        properties: {
          narrators: {
            type: "array",
            items: { type: "string" },
            description: "Ordered list of narrator names from Prophet → collector",
          },
        },
        required: ["narrators"],
      },
    },
    {
      name: "get_biography",
      description: "Get a detailed biography of a narrator from classical rijal works (Ibn Hajar, al-Dhahabi, etc.).",
      inputSchema: {
        type: "object",
        properties: {
          narrator_id: { type: "string", description: "Narrator database ID from lookup_narrator" },
        },
        required: ["narrator_id"],
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    if (name === "lookup_narrator") {
      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            name: args?.name,
            grade: "Thiqah (Reliable)",
            era: "Tabi'un",
            teachers: ["Imam Malik", "Nafi'"],
            students: ["Imam al-Shafi'i"]
          }, null, 2)
        }]
      };
    }

    if (name === "validate_chain") {
      const narrators = (args?.narrators as string[]) ?? [];
      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            valid: true,
            confidence: 0.95,
            remarks: "Chain is continuous and narrators are reliable."
          }, null, 2)
        }]
      };
    }

    if (name === "get_biography") {
      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            narrator_id: args?.narrator_id,
            biography: "MOCK: This is a detailed biography of the narrator from classical works..."
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
console.error("[mcp-rijal] server running on stdio (MOCK MODE)");
