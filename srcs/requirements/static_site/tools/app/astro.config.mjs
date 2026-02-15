// @ts-check
import { defineConfig } from "astro/config";

import tailwindcss from "@tailwindcss/vite";
import node from "@astrojs/node";

// https://astro.build/config
export default defineConfig({
  base: "/docs/",
  vite: {
    plugins: [tailwindcss()],
  },
  adapter: node({ mode: "standalone" }),
  server: {
    port: 4321,
    host: "0.0.0.0",
    allowedHosts: ["jtivan-r.42.fr"],
  },
});
