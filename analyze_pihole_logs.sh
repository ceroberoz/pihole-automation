#!/bin/bash

# Get the script's directory (Git repo root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR" || exit 1

INPUT_DB="/etc/pihole/pihole-FTL.db"
OUTPUT_ALLOWED="$SCRIPT_DIR/top50_allowed.txt"
OUTPUT_BLOCKED="$SCRIPT_DIR/top50_blocked.txt"

# Check dependencies
if ! command -v sqlite3 &> /dev/null; then
    echo "Installing sqlite3..."
    apt-get update && apt-get install -y sqlite3
fi

# Get top domains
echo "Analyzing Pi-hole query data..."
sqlite3 "$INPUT_DB" "SELECT domain, COUNT(domain) FROM queries WHERE status = 2 GROUP BY domain ORDER BY COUNT(domain) DESC LIMIT 50;" > "$OUTPUT_ALLOWED"
sqlite3 "$INPUT_DB" "SELECT domain, COUNT(domain) FROM queries WHERE status = 1 GROUP BY domain ORDER BY COUNT(domain) DESC LIMIT 50;" > "$OUTPUT_BLOCKED"

# Format output
sed -i 's/|/ /g' "$OUTPUT_ALLOWED"
sed -i 's/|/ /g' "$OUTPUT_BLOCKED"

echo "Results saved to:"
echo "- $OUTPUT_ALLOWED"
echo "- $OUTPUT_BLOCKED"
