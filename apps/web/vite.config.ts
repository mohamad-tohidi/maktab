import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      // Proxy all opencode API calls to avoid CORS in dev
      "/session": {
        target: "http://localhost:4096",
        changeOrigin: true,
      },
      "/event": {
        target: "http://localhost:4096",
        changeOrigin: true,
      },
      "/global": {
        target: "http://localhost:4096",
        changeOrigin: true,
      },
      "/agent": {
        target: "http://localhost:4096",
        changeOrigin: true,
      },
      "/mcp": {
        target: "http://localhost:4096",
        changeOrigin: true,
      },
    },
  },
  // When bundled for Tauri, assets are served from the webview
  base: process.env.TAURI_ENV_PLATFORM ? "./" : "/",
});
