import React, { useState, useEffect, useRef } from "react";
import { createSession, sendPrompt } from "./lib/opencode";

/**
 * Maktab — root component
 */
export default function App() {
  const [activeAgent, setActiveAgent] = useState<"hadith" | "fiqh" | "manuscript" | "translation">("hadith");

  const agents = [
    { id: "hadith",      label: "حديث",    en: "Hadith analyst"     },
    { id: "fiqh",        label: "فقه",      en: "Fiqh comparatist"  },
    { id: "manuscript",  label: "مخطوطة",   en: "Manuscript"        },
    { id: "translation", label: "ترجمة",   en: "Translation"        },
  ] as const;

  return (
    <div style={{ display: "flex", height: "100dvh" }}>
      {/* ── Sidebar ── */}
      <aside style={{
        width: 220,
        background: "var(--bg-surface)",
        borderLeft: "1px solid var(--border)",
        display: "flex",
        flexDirection: "column",
        padding: "1rem 0",
      }}>
        <div style={{ padding: "0 1rem 1rem", borderBottom: "1px solid var(--border)" }}>
          <h1 style={{ fontSize: 22, fontWeight: 600, color: "var(--accent)", letterSpacing: "0.02em" }}>
            مکتب
          </h1>
          <p style={{ fontSize: 11, color: "var(--text-3)", marginTop: 2 }}>Islamic Research Workbench</p>
        </div>

        <nav style={{ padding: "0.75rem 0", flex: 1 }}>
          <p style={{ fontSize: 10, color: "var(--text-3)", padding: "0 1rem 0.5rem", textTransform: "uppercase", letterSpacing: "0.1em" }}>
            Research agent
          </p>
          {agents.map(a => (
            <button
              key={a.id}
              onClick={() => setActiveAgent(a.id)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                width: "100%",
                padding: "0.55rem 1rem",
                background: activeAgent === a.id ? "var(--bg-card)" : "transparent",
                border: "none",
                borderRight: activeAgent === a.id ? "2px solid var(--accent)" : "2px solid transparent",
                color: activeAgent === a.id ? "var(--text-1)" : "var(--text-2)",
                cursor: "pointer",
                fontSize: 13,
                textAlign: "right",
                direction: "rtl",
                transition: "background 0.15s",
              }}
            >
              <span style={{ fontSize: 16, fontFamily: "var(--font-arabic)" }}>{a.label}</span>
              <span style={{ color: "var(--text-3)", fontSize: 11 }}>{a.en}</span>
            </button>
          ))}
        </nav>

        <div style={{ padding: "0.75rem 1rem", borderTop: "1px solid var(--border)", fontSize: 11, color: "var(--text-3)" }}>
          opencode server: <span style={{ color: "var(--accent)" }}>localhost:4096</span>
        </div>
      </aside>

      {/* ── Main chat ── */}
      <main style={{ flex: 1, display: "flex", flexDirection: "column", overflow: "hidden" }}>
        <ChatPanel agentId={activeAgent} />
      </main>
    </div>
  );
}

/* ── Chat panel ── */
function ChatPanel({ agentId }: { agentId: string }) {
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Array<{ role: "user" | "assistant"; text: string }>>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const prevAgent = useRef(agentId);

  // Create a new session whenever the agent changes
  useEffect(() => {
    if (prevAgent.current !== agentId) {
      setMessages([]);
      setSessionId(null);
      prevAgent.current = agentId;
    }

    let cancelled = false;
    createSession(agentId).then(s => {
      if (!cancelled) setSessionId(s.id);
    }).catch(err => console.error("Failed to create session:", err));

    return () => { cancelled = true; };
  }, [agentId]);

  const send = async () => {
    if (!input.trim() || loading || !sessionId) return;
    const text = input.trim();
    setInput("");
    setMessages(m => [...m, { role: "user", text }]);
    setLoading(true);

    try {
      // POST to the real opencode API (proxied through Vite)
      const res = await sendPrompt(sessionId, text);
      // Extract text from assistant parts
      const assistantText = res.parts
        ?.filter((p: any) => p.type === "text")
        .map((p: any) => p.text)
        .join("") ?? "(no response)";
      setMessages(m => [...m, { role: "assistant", text: assistantText }]);
    } catch (e) {
      setMessages(m => [...m, { role: "assistant", text: `Error: ${String(e)}` }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      {/* Message list */}
      <div style={{ flex: 1, overflowY: "auto", padding: "1.5rem" }}>
        {messages.length === 0 && (
          <div style={{ textAlign: "center", marginTop: "20vh", color: "var(--text-3)" }}>
            <p style={{ fontSize: 32, fontFamily: "var(--font-arabic)", marginBottom: 8 }}>بسم الله</p>
            <p style={{ fontSize: 13 }}>
              {sessionId ? "Select an agent and begin your research" : "Connecting to opencode…"}
            </p>
          </div>
        )}
        {messages.map((m, i) => (
          <div key={i} style={{
            marginBottom: "1.25rem",
            display: "flex",
            justifyContent: m.role === "user" ? "flex-end" : "flex-start",
          }}>
            <div style={{
              maxWidth: "72%",
              background: m.role === "user" ? "var(--accent-dim)" : "var(--bg-card)",
              border: "1px solid var(--border)",
              borderRadius: "var(--radius)",
              padding: "0.75rem 1rem",
              fontSize: 14,
              lineHeight: 1.7,
              whiteSpace: "pre-wrap",
              direction: "auto",
            }}>
              {m.text}
            </div>
          </div>
        ))}
        {loading && (
          <div style={{ color: "var(--text-3)", fontSize: 13, padding: "0 0 1rem" }}>
            ● ● ●
          </div>
        )}
      </div>

      {/* Input bar */}
      <div style={{
        padding: "1rem 1.5rem",
        borderTop: "1px solid var(--border)",
        background: "var(--bg-surface)",
        display: "flex",
        gap: 8,
      }}>
        <input
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === "Enter" && !e.shiftKey && send()}
          placeholder={sessionId ? "Begin your research query…" : "Connecting to opencode server…"}
          disabled={!sessionId}
          style={{
            flex: 1,
            background: "var(--bg-card)",
            border: "1px solid var(--border)",
            borderRadius: "var(--radius)",
            color: "var(--text-1)",
            padding: "0.65rem 1rem",
            fontSize: 14,
            outline: "none",
            direction: "auto",
            opacity: sessionId ? 1 : 0.5,
          }}
        />
        <button
          onClick={send}
          disabled={loading || !input.trim() || !sessionId}
          style={{
            padding: "0.65rem 1.25rem",
            background: loading || !sessionId ? "var(--text-3)" : "var(--accent)",
            color: "#0f0e0d",
            border: "none",
            borderRadius: "var(--radius)",
            fontWeight: 600,
            fontSize: 13,
            cursor: loading || !sessionId ? "not-allowed" : "pointer",
          }}
        >
          ارسال
        </button>
      </div>
    </>
  );
}
