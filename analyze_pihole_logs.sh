#!/bin/bash

# Use Pi-hole's live query database instead of log file
INPUT_DB="/etc/pihole/pihole-FTL.db"
OUTPUT_ALLOWED="top50_allowed.txt"
OUTPUT_BLOCKED="top50_blocked.txt"

# Check if sqlite3 is installed
if ! command -v sqlite3 &> /dev/null; then
    echo "Installing sqlite3..."
    apt-get update && apt-get install -y sqlite3
fi

# Get top 50 allowed domains (status 2 = allowed)
sqlite3 "$INPUT_DB" "SELECT domain, COUNT(domain) FROM queries WHERE status = 2 GROUP BY domain ORDER BY COUNT(domain) DESC LIMIT 50;" > "$OUTPUT_ALLOWED"

# Get top 50 blocked domains (status 1 = blocked)
sqlite3 "$INPUT_DB" "SELECT domain, COUNT(domain) FROM queries WHERE status = 1 GROUP BY domain ORDER BY COUNT(domain) DESC LIMIT 50;" > "$OUTPUT_BLOCKED"

# Format the output files
sed -i 's/|/ /g' "$OUTPUT_ALLOWED"
sed -i 's/|/ /g' "$OUTPUT_BLOCKED"

echo "Top 50 Allowed Domains saved to: $OUTPUT_ALLOWED"
echo "Top 50 Blocked Domains saved to: $OUTPUT_BLOCKED"
