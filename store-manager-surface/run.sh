#!/bin/bash
# Portable Node runner for Salesforce Insurance Store Trends
NODE_EXEC=$(command -v node 2>/dev/null || echo /usr/local/lib/sf/bin/node)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$NODE_EXEC" "$SCRIPT_DIR/fetch_trends.js" "$@"
