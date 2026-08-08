#!/bin/bash
# Serve the docs website locally and open in browser

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOCS_DIR="$PROJECT_DIR/docs"
PORT="${PORT:-8000}"
HOST="${HOST:-127.0.0.1}"

echo "Serving docs at http://$HOST:$PORT"
echo "Press Ctrl+C to stop"

# Open the preview on macOS. Orb services expose it through an authenticated portal.
if [[ "${AMP_ORB:-}" != "1" ]] && command -v open >/dev/null; then
  (sleep 1 && open "http://$HOST:$PORT") &
fi

# Start local server
python3 -m http.server "$PORT" --bind "$HOST" --directory "$DOCS_DIR"
