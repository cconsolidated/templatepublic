#!/bin/sh
set -e

echo "📂 Injecting files from code.json (pure shell, no jq)..."

if [ ! -f code.json ]; then
  echo "❌ code.json not found."
  exit 1
fi

# Remove outer brackets and split into lines
# This assumes clean JSON: array of objects with "path" and "content"
sed '1d;$d' code.json | while read -r line; do
  # Extract path
  path=$(echo "$line" | sed -n 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  # Extract content
  content=$(echo "$line" | sed -n 's/.*"content"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p')

  # Skip if not found
  [ -z "$path" ] && continue

  # Clean escaped quotes and newlines
  clean_content=$(printf "%b" "$content")

  echo "📝 Writing to $path"

  # Make directory
  dir_path=$(dirname "$path")
  mkdir -p "$dir_path"

  # Write content
  printf "%s\n" "$clean_content" > "$path"
done

echo "✅ All files written."
