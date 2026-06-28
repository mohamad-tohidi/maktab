/**
 * opencode HTTP client
 * All paths are relative (proxied through Vite in dev → localhost:4096).
 */

const BASE = "";

export async function listSessions() {
  const r = await fetch(`${BASE}/session`);
  if (!r.ok) throw new Error(await r.text());
  return r.json();
}

export async function createSession(agentId = "hadith") {
  const r = await fetch(`${BASE}/session`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ agent: agentId }),
  });
  if (!r.ok) throw new Error(await r.text());
  return r.json() as Promise<{ id: string; title?: string }>;
}

export async function sendPrompt(sessionId: string, text: string) {
  const r = await fetch(`${BASE}/session/${sessionId}/message`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      parts: [{ type: "text", text }],
    }),
  });
  if (!r.ok) throw new Error(await r.text());
  return r.json() as Promise<{ info: object; parts: Array<{ type: string; text?: string }> }>;
}

/**
 * Stream SSE events from the global event bus, filtered to a session.
 * Calls onChunk for each text delta, onDone when the turn completes.
 */
export function streamSession(
  sessionId: string,
  onChunk: (text: string) => void,
  onDone: () => void,
  signal?: AbortSignal
) {
  const es = new EventSource(`${BASE}/event`);

  es.onmessage = (e) => {
    try {
      const event = JSON.parse(e.data);
      if (event.sessionID !== sessionId) return;
      if (event.type === "assistant.text.delta") onChunk(event.delta ?? "");
      if (event.type === "assistant.turn.complete") { onDone(); es.close(); }
    } catch {}
  };

  es.onerror = () => es.close();
  signal?.addEventListener("abort", () => es.close());
  return () => es.close();
}
