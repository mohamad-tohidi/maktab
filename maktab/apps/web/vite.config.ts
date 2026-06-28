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
