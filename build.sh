#!/bin/bash

# Set database to false by default unless already set
: "${database:=false}"

# Build the React application (directly, not via npm run build)
react-router build

# Transpile app/root.tsx to JS for the edge function
npx esbuild app/root.tsx \
  --bundle \
  --platform=neutral \
  --format=esm \
  --external:tailwindcss \
  --external:set-cookie-parser \
  --external:react \
  --external:react-dom \
  --external:react-router \
  --external:react-router-dom \
  --outfile=supabase/functions/app/root.js

# Create Supabase functions directory if it doesn't exist
mkdir -p supabase/functions/app

# Copy the built files to the Supabase functions directory
cp -r build/* supabase/functions/app/

# Only deploy to Supabase if database is enabled
if [ "$database" = "true" ]; then
  supabase functions deploy app
  echo "Build and deployment completed!"
else
  echo "Build completed! (Supabase deploy skipped because database=false)"
fi 