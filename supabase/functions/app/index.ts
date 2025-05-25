import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from '@supabase/supabase-js'
import { renderToString } from 'react-dom/server'
import { StaticRouter } from 'react-router-dom/server'
import { App } from '../../app/root'

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
const supabase = createClient(supabaseUrl, supabaseKey)

serve(async (req) => {
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
    <StaticRouter location={url.pathname}>
      <App />
    </StaticRouter>
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