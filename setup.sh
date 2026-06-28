#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
#  Maktab (مکتب) — Islamic Research Workbench
#  Project scaffold script
#  Usage: bash create-maktab.sh [target-directory]
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

TARGET="${1:-maktab}"
echo ""
echo "  مکتب  Maktab — creating project in ./$TARGET"
echo "──────────────────────────────────────────────────────────"

mkdir -p "$TARGET"
cd "$TARGET"

# ── 1. ROOT FILES ────────────────────────────────────────────────

cat >package.json <<'EOF'
{
  "name": "maktab",
  "version": "0.1.0",
  "private": true,
  "description": "مکتب — Islamic Research Workbench powered by opencode",
  "workspaces": [
    "apps/*",
    "packages/*"
  ],
  "scripts": {
    "dev": "npm run dev --workspace=apps/web",
    "dev:all": "concurrently \"npm run dev --workspace=apps/web\" \"npm run dev --workspace=apps/desktop\"",
    "build": "npm run build --workspace=apps/web && npm run build --workspace=apps/desktop",
    "opencode": "opencode serve --port 4096 --config .opencode/opencode.json"
  },
  "devDependencies": {
    "concurrently": "^9.0.0"
  }
}
EOF

cat >.gitignore <<'EOF'
node_modules/
dist/
.env
.env.local
*.log
target/
src-tauri/target/
.DS_Store
EOF

cat >README.md <<'HEREDOC'
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
HEREDOC

cat >.env.example <<'EOF'
# Copy this file to .env and fill in your keys
# opencode server port (keep in sync with apps/web/src/lib/opencode.ts)
OPENCODE_PORT=4096

# LLM provider — pick one
ANTHROPIC_API_KEY=sk-ant-...
# OPENAI_API_KEY=sk-...

# Your Hadith/Rijal API credentials
HADITH_API_BASE_URL=https://api.hadith.example.com
HADITH_API_KEY=
RIJAL_API_BASE_URL=https://api.rijal.example.com
RIJAL_API_KEY=
EOF

# ── 2. OPENCODE CONFIG BUNDLE ────────────────────────────────────

mkdir -p .opencode/agents .opencode/commands .opencode/skills .opencode/themes

cat >.opencode/opencode.json <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-6",
  "small_model": "anthropic/claude-haiku-4-5-20251001",
  "default_agent": "hadith",
  "autoupdate": false,
  "share": "disabled",
  "permission": {
    "edit": "ask",
    "bash": {
      "*": "deny",
      "curl *sunnah.com*": "allow",
      "curl *quran.com*": "allow"
    }
  },
  "instructions": [
    ".opencode/AGENTS.md",
    ".opencode/skills/arabic-transliteration.md",
    ".opencode/skills/hadith-grading.md",
    ".opencode/skills/usul-al-fiqh.md"
  ],
  "mcp": {
    "servers": {
      "hadith": {
        "type": "stdio",
        "command": "node",
        "args": ["../../packages/mcp-hadith/dist/index.js"],
        "env": {
          "HADITH_API_BASE_URL": "${HADITH_API_BASE_URL}",
          "HADITH_API_KEY": "${HADITH_API_KEY}"
        }
      },
      "rijal": {
        "type": "stdio",
        "command": "node",
        "args": ["../../packages/mcp-rijal/dist/index.js"],
        "env": {
          "RIJAL_API_BASE_URL": "${RIJAL_API_BASE_URL}",
          "RIJAL_API_KEY": "${RIJAL_API_KEY}"
        }
      }
    }
  }
}
EOF

cat >.opencode/AGENTS.md <<'HEREDOC'
# Maktab — Global Research Rules

You are a scholarly AI assistant specialising in Islamic studies.
Every session follows these rules without exception.

## Identity and tone
- Address the user as a fellow researcher, not a student.
- Use precise academic language. Avoid oversimplification.
- When uncertain about a ruling or attribution, say so clearly.

## Dates
- Always express dates in both Hijri (AH) and Gregorian (CE) formats.
- Example: "Ibn Hajar al-Asqalani (773–852 AH / 1372–1449 CE)"

## Arabic terms
- Transliterate Arabic using IJMES (International Journal of Middle East Studies) convention.
- Always include the original Arabic script alongside transliterations on first use.
- Example: "isnad (إسناد)" not just "isnad".

## Source citations
- Prefer primary sources (Quran, canonical hadith collections, classical fiqh texts).
- When citing secondary sources, note their scholarly standing.
- Format citations as: Author, *Title* (place: publisher, year), volume:page.

## Scholarly neutrality
- Do not issue fatawa (legal rulings). Present scholarly opinions, not personal guidance.
- When madhhab positions differ, present all relevant positions (Hanafi, Maliki, Shafi'i, Hanbali).
- Note whether a position is a minority (shadhdh) view.

## Hadith work
- Always note the collector (Bukhari, Muslim, Abu Dawud, etc.) and kitab/bab location.
- Include the grading (sahih/hasan/da'if) and which scholar graded it.
- Flag any known disputes about a hadith's authenticity.

## Do not
- Issue fatwas or personal religious guidance.
- Conflate modern Salafi positions with classical Hanbali fiqh.
- Use anachronistic modern frameworks to analyse premodern scholars.
HEREDOC

# ── Agents ────────────────────────────────────────────────────────

cat >.opencode/agents/hadith.md <<'HEREDOC'
---
description: "Primary agent for hadith research — chain analysis, narrator evaluation, and cross-collection search"
temperature: 0.1
model: anthropic/claude-sonnet-4-6
tools:
  - hadith:search_hadith
  - hadith:get_chain
  - rijal:lookup_narrator
  - rijal:validate_chain
  - rijal:get_biography
mode: primary
---

You are an expert in hadith sciences (علوم الحديث, ulum al-hadith).

Your primary tasks:
1. **Isnad analysis** — trace the chain of transmission, identify each narrator,
   retrieve their biography and reliability rating from the rijal database.
2. **Cross-collection search** — find parallel transmissions of the same matn
   (text) across different collections (Bukhari, Muslim, Tirmidhi, etc.).
3. **Grading** — synthesise narrator evaluations into an overall hadith grading
   following the methodology of classical hadith critics.

Always use the MCP tools to fetch live data. Never rely solely on your training
knowledge for narrator assessments — always validate via the rijal tool.

Output format for chain analysis:
- Narrator name (Arabic + transliteration) → reliability rating → source
- Flag: tadlis (تدليس), inqita (انقطاع), idtirab (اضطراب) where present
- Conclude with overall grading and justification.
HEREDOC

cat >.opencode/agents/fiqh.md <<'HEREDOC'
---
description: "Comparative fiqh agent — presents rulings across all four Sunni madhhabs with their dalil"
temperature: 0.2
model: anthropic/claude-sonnet-4-6
mode: primary
---

You are an expert in comparative Islamic jurisprudence (فقه مقارن, fiqh muqaran).

For any legal question (mas'ala), structure your response as:

## [Topic] — Comparative Analysis

**Hanafi position**: [ruling] — Dalil: [evidence]
**Maliki position**: [ruling] — Dalil: [evidence]
**Shafi'i position**: [ruling] — Dalil: [evidence]
**Hanbali position**: [ruling] — Dalil: [evidence]

**Points of consensus (ijma')**: [if any]
**Points of disagreement (ikhtilaf)**: [summary]
**Usul al-fiqh basis**: [which legal principles drive the disagreement]

Always cite the authoritative text within each madhhab
(e.g., al-Mabsut for Hanafi, al-Mudawwana for Maliki).
Do not issue a preferred ruling — present the scholarly landscape.
HEREDOC

cat >.opencode/agents/manuscript.md <<'HEREDOC'
---
description: "Manuscript processing agent — transcription, codicology metadata, and TEI-XML scaffolding"
temperature: 0.1
model: anthropic/claude-sonnet-4-6
mode: primary
---

You are a specialist in Islamic manuscript studies and digital codicology.

Your tasks:
1. **Transcription assistance** — clean OCR output of Arabic manuscripts,
   flag unclear passages with [?], note alternate readings.
2. **Codicological metadata** — extract and structure: scribal colophon,
   date of copying, script type (naskh/nasta'liq/maghribi), material, dimensions.
3. **TEI-XML scaffolding** — produce a valid TEI P5 XML skeleton for the manuscript,
   including <msDesc>, <msIdentifier>, <physDesc>, and <history> elements.
4. **Provenance notes** — flag waqf seals, ownership stamps, marginal annotations.

Use formal academic catalogue language (similar to British Library Or. series).
HEREDOC

cat >.opencode/agents/translation.md <<'HEREDOC'
---
description: "Classical Arabic translation assistant — renders classical texts into scholarly English with register awareness"
temperature: 0.3
model: anthropic/claude-sonnet-4-6
mode: subagent
---

You translate classical Arabic (7th–19th century) into scholarly English.

Register levels you must distinguish:
- **Running translation** — readable prose for the body of an academic article
- **Literal gloss** — word-by-word for linguistic analysis
- **Footnote rendering** — concise, with key terms retained in Arabic

Always:
- Retain key technical terms in Arabic (transliterated) on first use
- Note where the Arabic is syntactically ambiguous
- Flag hapax legomena or rare vocabulary
- Indicate if a phrase has legal/theological technical meaning beyond its literal sense
HEREDOC

# ── Slash commands ────────────────────────────────────────────────

cat >.opencode/commands/hadith-search.md <<'HEREDOC'
Search for hadith by keyword or topic across all major collections.

RUN echo "Searching hadith collections for: $QUERY"

Search for hadith related to: $QUERY

Use the hadith:search_hadith tool to find relevant narrations.
For each result, show: collector, book/chapter, narrator chain summary,
and grading. Present results in Arabic with IJMES transliteration.
HEREDOC

cat >.opencode/commands/chain-check.md <<'HEREDOC'
Analyse the isnad (chain of narrators) of a hadith.

Paste the full isnad below and I will:
1. Identify each narrator
2. Look up their biographical data and reliability
3. Check for breaks or weaknesses in the chain
4. Provide an overall grading

Isnad to analyse:
$ISNAD
HEREDOC

cat >.opencode/commands/madhhab-compare.md <<'HEREDOC'
Compare the four Sunni madhhab positions on a fiqh question.

Question: $QUESTION

Use the fiqh agent to present all four positions with their dalil (evidence),
points of consensus, and the usul al-fiqh basis for any disagreement.
HEREDOC

cat >.opencode/commands/cite-arabic.md <<'HEREDOC'
Format an Arabic source citation in IJMES academic style.

Source details:
- Author: $AUTHOR
- Title (Arabic): $TITLE
- Editor/translator (if any): $EDITOR
- Place of publication: $PLACE
- Publisher: $PUBLISHER
- Year (Hijri and/or Gregorian): $YEAR
- Volume and page: $VOL_PAGE

Produce: full IJMES footnote citation, short-form (ibid) citation,
and bibliography entry.
HEREDOC

# ── Skills (knowledge files) ──────────────────────────────────────

cat >.opencode/skills/hadith-grading.md <<'HEREDOC'
# Hadith grading vocabulary (علم مصطلح الحديث)

## Accepted grades (مقبول)
- **Sahih (صحيح)** — sound: continuous chain, reliable narrators, no shadhdh or 'illa
- **Hasan (حسن)** — good: meets sahih criteria but with slightly less precise memorisation
- **Sahih li-ghayrihi** — raised to sahih by corroborating chains
- **Hasan li-ghayrihi** — raised to hasan by corroborating chains

## Rejected grades (مردود)
- **Da'if (ضعيف)** — weak: chain defect or narrator weakness
- **Munkar (منكر)** — denounced: narrated only by a weak narrator, contradicts stronger
- **Mawdu' (موضوع)** — fabricated: forged, not attributed to the Prophet

## Chain defects (علل)
- **Munqati' (منقطع)** — broken chain (non-consecutive)
- **Mu'allaq (معلق)** — suspended (missing narrators at beginning)
- **Mursal (مرسل)** — missing Companion link
- **Mu'dal (معضل)** — two or more consecutive missing narrators
- **Tadlis (تدليس)** — narrator concealing a weakness in their transmission
- **Idtirab (اضطراب)** — contradictory versions from same narrator

## Key scholars and their grading criteria
- Ibn Hajar al-Asqalani: Nukhbat al-Fikr — standard reference
- al-Nawawi: stricter on hasan threshold
- al-Albani: modern re-grader, sometimes controversial
HEREDOC

cat >.opencode/skills/arabic-transliteration.md <<'HEREDOC'
# Arabic Transliteration — IJMES System

Use the International Journal of Middle East Studies (IJMES) transliteration
for all Arabic terms.

## Key characters
ء = ' (hamza)    ع = ' (ayn)
ā = ا (alif)     ī = ي (ya maddah)    ū = و (waw maddah)
ḥ = ح            ḫ = خ (not used in IJMES — use kh)
kh = خ           gh = غ           sh = ش
ṣ = ص            ḍ = ض            ṭ = ط            ẓ = ظ
th = ث           dh = ذ

## Rules
- Article: al- (always lowercase, even after punctuation)
- Sun letters: write phonetically — al-Shafi'i NOT ash-Shafi'i (in IJMES)
- Tashkil (diacritics): only add in quotations, not in running text
- Tā' marbūṭa: -a in construct state, -at in iḍāfa

## Common terms
- isnad (إسناد), matn (متن), sanad (سند)
- fiqh (فقه), usul (أصول), furū' (فروع)
- hadith (حديث), khabar (خبر), athar (أثر)
- ijaz (إجازة), waqf (وقف), naskh (نسخ)
HEREDOC

cat >.opencode/skills/usul-al-fiqh.md <<'HEREDOC'
# Usul al-Fiqh — Foundations of Islamic Law

## Primary sources (الأدلة الأصلية)
1. **Quran (القرآن)** — definitive text; qat'i al-wurud
2. **Sunnah (السنة)** — graded by hadith sciences; mutawatir vs ahad
3. **Ijma' (الإجماع)** — scholarly consensus; strongest after Quran & Sunnah
4. **Qiyas (القياس)** — analogical reasoning; requires 'illa (ratio legis)

## Secondary sources (الأدلة التبعية — vary by madhhab)
- **Istihsan (استحسان)** — juristic preference (Hanafi/Maliki)
- **Masalih mursalah (مصالح مرسلة)** — public interest (Maliki)
- **'Urf (عرف)** — custom
- **Sadd al-dhara'i' (سد الذرائع)** — blocking means to harm (Maliki/Hanbali)
- **Istishab (استصحاب)** — presumption of continuity

## Legal categories (الأحكام التكليفية)
- Wajib/Fard (واجب/فرض) — obligatory
- Mandub/Mustahabb (مندوب/مستحب) — recommended
- Mubah (مباح) — permitted/neutral
- Makruh (مكروه) — discouraged
- Haram (حرام) — forbidden

## Madhhab usul differences
- Hanafi: favours ra'y (opinion), uses istihsan widely, accepts mursal hadith
- Maliki: relies on 'amal ahl al-Madina (practice of Medina), masalih mursalah
- Shafi'i: strict on hadith requirements, limits qiyas, codified usul in al-Risala
- Hanbali: very hadith-centric, restricts ra'y, accepts weak hadith over qiyas
HEREDOC

# ── 3. FRONTEND — apps/web ───────────────────────────────────────

mkdir -p apps/web/src/{components,lib,pages,styles,assets}
mkdir -p apps/web/public

cat >apps/web/package.json <<'EOF'
{
  "name": "@maktab/web",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "@opencode-ai/sdk": "latest",
    "react": "^18.3.0",
    "react-dom": "^18.3.0"
  },
  "devDependencies": {
    "@types/react": "^18.3.0",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.0",
    "typescript": "^5.5.0",
    "vite": "^5.4.0"
  }
}
EOF

cat >apps/web/vite.config.ts <<'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      // Proxy opencode API calls so the frontend doesn't need CORS config
      "/v1": {
        target: "http://localhost:4096",
        changeOrigin: true,
      },
    },
  },
  // When bundled for Tauri, assets are served from the webview
  base: process.env.TAURI_ENV_PLATFORM ? "./" : "/",
});
EOF

cat >apps/web/tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true
  },
  "include": ["src"]
}
EOF

cat >apps/web/index.html <<'EOF'
<!doctype html>
<html lang="fa" dir="rtl">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="مکتب — Islamic Research Workbench" />
    <title>مکتب — Maktab</title>
    <link rel="icon" type="image/svg+xml" href="/icon.svg" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

# opencode client helper
cat >apps/web/src/lib/opencode.ts <<'EOF'
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
EOF

# Styles
cat >apps/web/src/styles/globals.css <<'EOF'
/* ── Maktab design tokens ─────────────────────────────── */
:root {
  --bg:          #0f0e0d;
  --bg-surface:  #181714;
  --bg-card:     #1f1c19;
  --border:      #2e2b26;
  --text-1:      #e8e0d5;
  --text-2:      #a09080;
  --text-3:      #5a5248;
  --accent:      #c4a265;      /* warm gold — ink colour */
  --accent-dim:  #7a6340;
  --danger:      #a03030;
  --font-arabic: "Noto Naskh Arabic", "Amiri", "Cairo", serif;
  --font-ui:     "Geist", "Inter", system-ui, sans-serif;
  --radius:      8px;
}

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

html { font-size: 16px; }

body {
  background: var(--bg);
  color: var(--text-1);
  font-family: var(--font-ui);
  line-height: 1.6;
  min-height: 100dvh;
}

/* Arabic text passages use the naskh font */
.arabic {
  font-family: var(--font-arabic);
  font-size: 1.2em;
  line-height: 2;
  direction: rtl;
}

/* Scrollbars */
::-webkit-scrollbar { width: 4px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--border); border-radius: 2px; }

/* Selection */
::selection { background: var(--accent-dim); color: var(--text-1); }
EOF

# React entry
cat >apps/web/src/main.tsx <<'EOF'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./styles/globals.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# App root
cat >apps/web/src/App.tsx <<'EOF'
import React, { useState } from "react";

/**
 * Maktab — root component
 *
 * Layout: sidebar (session list + agent picker) + main chat area.
 * This is a minimal scaffold — see components/ for each piece.
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
        borderLeft: "1px solid var(--border)",  /* RTL: border on left = right side visually */
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

/* ── Inline chat panel (extracted to components/ChatPanel.tsx later) ── */
function ChatPanel({ agentId }: { agentId: string }) {
  const [messages, setMessages] = useState<Array<{ role: "user"|"assistant"; text: string }>>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);

  const send = async () => {
    if (!input.trim() || loading) return;
    const text = input.trim();
    setInput("");
    setMessages(m => [...m, { role: "user", text }]);
    setLoading(true);

    try {
      // Real implementation: POST to opencode server, then stream SSE
      // See src/lib/opencode.ts for the SDK helpers
      const res = await fetch("/v1/session/prompt", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ agent: agentId, text }),
      });
      const data = await res.json();
      setMessages(m => [...m, { role: "assistant", text: data.text ?? "(no response)" }]);
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
            <p style={{ fontSize: 13 }}>Select an agent and begin your research</p>
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
          placeholder="Begin your research query…"
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
          }}
        />
        <button
          onClick={send}
          disabled={loading || !input.trim()}
          style={{
            padding: "0.65rem 1.25rem",
            background: loading ? "var(--text-3)" : "var(--accent)",
            color: "#0f0e0d",
            border: "none",
            borderRadius: "var(--radius)",
            fontWeight: 600,
            fontSize: 13,
            cursor: loading ? "not-allowed" : "pointer",
          }}
        >
          ارسال
        </button>
      </div>
    </>
  );
}
EOF

# SVG icon for the app
cat >apps/web/public/icon.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none">
  <rect width="64" height="64" rx="14" fill="#1f1c19"/>
  <text x="32" y="44" text-anchor="middle" font-family="serif" font-size="34" fill="#c4a265">م</text>
</svg>
EOF

# ── 4. DESKTOP — apps/desktop (Tauri) ───────────────────────────

mkdir -p apps/desktop/src-tauri/src
mkdir -p apps/desktop/src-tauri/icons

cat >apps/desktop/package.json <<'EOF'
{
  "name": "@maktab/desktop",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "tauri dev",
    "build": "tauri build",
    "tauri": "tauri"
  },
  "dependencies": {},
  "devDependencies": {
    "@tauri-apps/cli": "^2.0.0",
    "@tauri-apps/api": "^2.0.0"
  }
}
EOF

cat >apps/desktop/src-tauri/Cargo.toml <<'EOF'
[package]
name = "maktab"
version = "0.1.0"
description = "مکتب — Islamic Research Workbench"
authors = ["Maktab Team"]
edition = "2021"

[lib]
name = "maktab_lib"
crate-type = ["staticlib", "cdylib", "rlib"]

[[bin]]
name = "maktab"
path = "src/main.rs"

[build-dependencies]
tauri-build = { version = "2", features = [] }

[dependencies]
tauri = { version = "2", features = ["shell-open"] }
tauri-plugin-shell = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
EOF

cat >apps/desktop/src-tauri/src/main.rs <<'EOF'
// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    maktab_lib::run()
}
EOF

cat >apps/desktop/src-tauri/src/lib.rs <<'EOF'
use tauri::Manager;
use std::process::{Command, Child};
use std::sync::Mutex;

struct OpencodeProcess(Mutex<Option<Child>>);

#[tauri::command]
fn get_opencode_port() -> u16 {
    4096
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .manage(OpencodeProcess(Mutex::new(None)))
        .setup(|app| {
            // Launch opencode server as a sidecar process
            let config_dir = app
                .path()
                .resource_dir()
                .expect("resource dir")
                .join(".opencode");

            let child = Command::new("opencode")
                .args(["serve", "--port", "4096", "--config"])
                .arg(config_dir.join("opencode.json"))
                .spawn()
                .expect("Failed to start opencode server");

            *app.state::<OpencodeProcess>().0.lock().unwrap() = Some(child);
            Ok(())
        })
        .on_window_event(|_window, event| {
            // Clean up opencode process on window close
            if let tauri::WindowEvent::Destroyed = event {
                // Process cleanup handled by OS when parent exits
            }
        })
        .invoke_handler(tauri::generate_handler![get_opencode_port])
        .run(tauri::generate_context!())
        .expect("error while running Maktab");
}
EOF

cat >apps/desktop/src-tauri/tauri.conf.json <<'EOF'
{
  "$schema": "https://schema.tauri.app/config/2",
  "productName": "Maktab",
  "identifier": "ai.maktab.app",
  "version": "0.1.0",
  "build": {
    "frontendDist": "../../apps/web/dist",
    "devUrl": "http://localhost:5173",
    "beforeDevCommand": "",
    "beforeBuildCommand": "npm run build --workspace=apps/web"
  },
  "app": {
    "windows": [
      {
        "title": "مکتب — Maktab",
        "width": 1280,
        "height": 820,
        "minWidth": 900,
        "minHeight": 600,
        "resizable": true,
        "fullscreen": false,
        "decorations": true
      }
    ],
    "security": {
      "csp": "default-src 'self'; connect-src 'self' http://localhost:4096; style-src 'self' 'unsafe-inline'"
    }
  },
  "bundle": {
    "active": true,
    "targets": "all",
    "icon": [
      "icons/icon.png",
      "icons/icon.ico"
    ],
    "windows": {
      "wix": {
        "language": "en-US"
      }
    }
  }
}
EOF

# Sidecar resources dir (opencode binary will be bundled here in prod)
mkdir -p apps/desktop/src-tauri/resources
cat >apps/desktop/src-tauri/resources/.gitkeep <<'EOF'
# Place the opencode binary here for bundling.
# During development, opencode is expected to be on PATH.
# For production builds, run: scripts/bundle-opencode.sh
EOF

# ── 5. MCP SERVER — packages/mcp-hadith ──────────────────────────

mkdir -p packages/mcp-hadith/src

cat >packages/mcp-hadith/package.json <<'EOF'
{
  "name": "@maktab/mcp-hadith",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsc --watch",
    "build": "tsc"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "@types/node": "^22.0.0"
  }
}
EOF

cat >packages/mcp-hadith/tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "dist",
    "strict": true,
    "esModuleInterop": true
  },
  "include": ["src"]
}
EOF

cat >packages/mcp-hadith/src/index.ts <<'EOF'
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
EOF

# ── 6. MCP SERVER — packages/mcp-rijal ──────────────────────────

mkdir -p packages/mcp-rijal/src

cat >packages/mcp-rijal/package.json <<'EOF'
{
  "name": "@maktab/mcp-rijal",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsc --watch",
    "build": "tsc"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "@types/node": "^22.0.0"
  }
}
EOF

cat >packages/mcp-rijal/tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "dist",
    "strict": true,
    "esModuleInterop": true
  },
  "include": ["src"]
}
EOF

cat >packages/mcp-rijal/src/index.ts <<'EOF'
/**
 * Maktab — Rijal MCP Server
 *
 * Exposes narrator validation and biography tools.
 *   lookup_narrator  — find narrator by name, get bio + grades
 *   validate_chain   — assess a full isnad as an array of names
 *   get_biography    — detailed biography from classical rijal works
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const API_BASE = process.env.RIJAL_API_BASE_URL ?? "https://api.rijal.example.com";
const API_KEY  = process.env.RIJAL_API_KEY ?? "";

async function apiGet(path: string, params: Record<string, string> = {}) {
  const url = new URL(`${API_BASE}${path}`);
  Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, v));
  const res = await fetch(url.toString(), {
    headers: { Authorization: `Bearer ${API_KEY}` },
  });
  if (!res.ok) throw new Error(`Rijal API error: ${res.status}`);
  return res.json();
}

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
      const data = await apiGet("/v1/narrator/search", {
        name: String(args?.name ?? ""),
      });
      return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
    }

    if (name === "validate_chain") {
      const narrators = (args?.narrators as string[]) ?? [];
      const data = await apiGet("/v1/chain/validate", {
        narrators: narrators.join(","),
      });
      return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
    }

    if (name === "get_biography") {
      const data = await apiGet(`/v1/narrator/${args?.narrator_id}/biography`);
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
console.error("[mcp-rijal] server running on stdio");
EOF

# ── 7. SCRIPTS ───────────────────────────────────────────────────

mkdir -p scripts

cat >scripts/dev.sh <<'EOF'
#!/usr/bin/env bash
# Start everything for local development
set -euo pipefail

# Load .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

echo "→ Building MCP servers..."
npm run build --workspace=packages/mcp-hadith
npm run build --workspace=packages/mcp-rijal

echo "→ Starting opencode server on :4096..."
opencode serve --port 4096 --config .opencode/opencode.json &
OPENCODE_PID=$!

echo "→ Starting Vite dev server on :5173..."
npm run dev --workspace=apps/web &
VITE_PID=$!

echo ""
echo "  مکتب  Maktab is running"
echo "  Frontend : http://localhost:5173"
echo "  OpenCode : http://localhost:4096"
echo ""
echo "  Ctrl+C to stop all"

# Clean up on exit
trap "kill $OPENCODE_PID $VITE_PID 2>/dev/null" EXIT
wait
EOF
chmod +x scripts/dev.sh

cat >scripts/bundle-opencode.sh <<'EOF'
#!/usr/bin/env bash
# Download the opencode binary for bundling into the Tauri app.
# This runs before `tauri build` in CI.
set -euo pipefail

PLATFORM="${1:-windows-x64}"   # windows-x64 | darwin-arm64 | linux-x64
DEST="apps/desktop/src-tauri/resources/opencode"
VERSION="latest"

echo "→ Downloading opencode $VERSION for $PLATFORM..."

case "$PLATFORM" in
  windows-x64)  EXT=".exe"; TRIPLE="x86_64-pc-windows-msvc" ;;
  darwin-arm64) EXT="";     TRIPLE="aarch64-apple-darwin" ;;
  linux-x64)    EXT="";     TRIPLE="x86_64-unknown-linux-gnu" ;;
esac

curl -fsSL "https://github.com/anomalyco/opencode/releases/latest/download/opencode_${TRIPLE}${EXT}" \
  -o "${DEST}${EXT}"

chmod +x "${DEST}${EXT}"
echo "→ opencode binary saved to ${DEST}${EXT}"
EOF
chmod +x scripts/bundle-opencode.sh

# ── 8. DONE ──────────────────────────────────────────────────────

echo ""
echo "  ✓ Project created in ./$TARGET"
echo ""
echo "  Next steps:"
echo ""
echo "  1.  cd $TARGET"
echo "  2.  cp .env.example .env   # and add your API keys"
echo "  3.  npm install"
echo "  4.  npm i -g opencode-ai@latest   # install opencode globally"
echo "  5.  bash scripts/dev.sh           # start everything"
echo ""
echo "  To build the Windows .exe later:"
echo "  6.  bash scripts/bundle-opencode.sh windows-x64"
echo "  7.  npm run build --workspace=apps/desktop"
echo ""
