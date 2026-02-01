#!/bin/bash
# Serve the docs website locally and open in browser

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOCS_DIR="$PROJECT_DIR/docs"
PORT=8000

echo "Serving docs at http://localhost:$PORT"
echo "Press Ctrl+C to stop"

# Open browser after a short delay
(sleep 1 && open "http://localhost:$PORT") &

# Start local server
cd "$DOCS_DIR"
python3 -m http.server $PORT
