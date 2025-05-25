import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
// Conditionally import Supabase only if database is enabled
// @ts-ignore
const useDatabase = Deno.env.get('database') === 'true'
let supabase = null
if (useDatabase) {
  const { createClient } = await import('@supabase/supabase-js')
  // @ts-ignore
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  // @ts-ignore
  const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')
  if (supabaseUrl && supabaseKey) {
    supabase = createClient(supabaseUrl, supabaseKey)
  }
}
import { renderToString } from 'react-dom/server'
import { StaticRouter } from 'react-router-dom/server'
import React from 'react'
// @ts-ignore
import { App } from './root.js'

serve(async (req: Request) => {
  const url = new URL(req.url)
  
  // Handle API routes
  if (url.pathname.startsWith('/api/')) {
    // Add your API route handlers here
    return new Response(JSON.stringify({ message: 'API endpoint' }), {
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Serve the React application
  const html = renderToString(
    React.createElement(
      StaticRouter,
      { location: url.pathname },
      React.createElement(App)
    )
  )

  return new Response(
    `<!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>React App</title>
        <link rel="stylesheet" href="/app.css">
      </head>
      <body>
        <div id="root">${html}</div>
        <script type="module" src="/entry.client.js"></script>
      </body>
    </html>`,
    {
      headers: {
        'Content-Type': 'text/html',
      },
    }
  )
}) 