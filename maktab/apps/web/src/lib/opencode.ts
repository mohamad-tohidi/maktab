/**
 * opencode SDK client
 * Connects to the local opencode server (proxied through Vite in dev,
 * or directly at localhost:4096 in production/Tauri).
 */
import Opencode from "@opencode-ai/sdk";

const BASE_URL =
  import.meta.env.VITE_OPENCODE_URL ?? "http://localhost:4096";

export const client = new Opencode({ baseURL: BASE_URL });

// ── Session helpers ───────────────────────────────────────────────

export async function listSessions() {
  return client.session.list();
}

export async function createSession(agentId = "hadith") {
  return client.session.create({ agent: agentId });
}

export async function sendPrompt(sessionId: string, text: string) {
  return client.session.prompt(sessionId, { text });
}

/**
 * Stream SSE events from a session.
 * Calls onChunk for each text delta and onDone when the turn completes.
 */
export async function streamSession(
  sessionId: string,
  onChunk: (text: string) => void,
  onDone: () => void
) {
  const stream = await client.event.list({ sessionId });
  for await (const event of stream) {
    if (event.type === "assistant.text.delta") {
      onChunk(event.delta ?? "");
    } else if (event.type === "assistant.turn.complete") {
      onDone();
      break;
    }
  }
}
