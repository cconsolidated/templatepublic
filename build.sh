#!/bin/bash

# Build the React application
npm run build

# Create Supabase functions directory if it doesn't exist
mkdir -p supabase/functions/app

# Copy the built files to the Supabase functions directory
cp -r build/* supabase/functions/app/

# Deploy to Supabase
supabase functions deploy app

echo "Build and deployment completed!" 