/**
 * opencode HTTP client
 * Paths are relative — proxied by Vite in dev to http://localhost:4096
 *
 * API reference: https://opencode.ai/docs/server/
 */

/** Create a blank session. Agent is chosen per-message, not per-session. */
export async function createSession(title?: string) {
  const r = await fetch("/session", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(title ? { title } : {}),
  });
  if (!r.ok) throw new Error(`createSession ${r.status}: ${await r.text()}`);
  return r.json() as Promise<{ id: string; title?: string }>;
}

/**
 * Send a message and wait for the full response.
 * `agent` selects which opencode agent handles the message.
 * Returns the assistant message with all its parts.
 */
export async function sendPrompt(sessionId: string, text: string, agent: string) {
  const r = await fetch(`/session/${sessionId}/message`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      agent,
      parts: [{ type: "text", text }],
    }),
  });
  if (!r.ok) throw new Error(`sendPrompt ${r.status}: ${await r.text()}`);
  return r.json() as Promise<{ info: object; parts: Array<{ type: string; text?: string }> }>;
}

export async function listSessions() {
  const r = await fetch("/session");
  if (!r.ok) throw new Error(`listSessions ${r.status}: ${await r.text()}`);
  return r.json();
}

/** Subscribe to SSE events, filtered to a session. Returns unsubscribe fn. */
export function streamSession(
  sessionId: string,
  onChunk: (text: string) => void,
  onDone: () => void,
  signal?: AbortSignal
) {
  const es = new EventSource("/event");
  es.onmessage = (e) => {
    try {
      const ev = JSON.parse(e.data);
      if (ev.sessionID !== sessionId) return;
      if (ev.type === "assistant.text.delta") onChunk(ev.delta ?? "");
      if (ev.type === "assistant.turn.complete") { onDone(); es.close(); }
    } catch {}
  };
  es.onerror = () => es.close();
  signal?.addEventListener("abort", () => es.close());
  return () => es.close();
}
