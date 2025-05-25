import type { Config } from "@react-router/dev/config";

export default {
  // Enable SSR for server-side rendering
  ssr: true,
  
  // Configure routes
  routes: {
    // Use file-based routing from app/routes
    dir: "app/routes",
    // Include API routes from pages/api
    api: "pages/api",
  },
  
  // Configure build output
  outDir: {
    client: "build/client",
    server: "build/server",
  },
} satisfies Config;
