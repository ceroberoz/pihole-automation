#!/bin/bash

# Configuration
WORKDIR="/root/pihole-dynamic-domains"
BACKUP_DIR="$WORKDIR/backups"
LOG_FILE="$WORKDIR/pihole_update.log"
TIMESTAMP=$(date +"%Y-%m-%d %T")

# Create directories if missing
mkdir -p "$BACKUP_DIR"

# Start logging
{
echo "=== Pi-hole Auto-Update Started at $TIMESTAMP ==="

# Step 1: Analyze traffic
echo -n "Analyzing traffic... "
cd "$WORKDIR" || exit 1
if ! ./analyze_pihole_logs.sh >> "$LOG_FILE" 2>&1; then
    echo "FAILED!"
    exit 1
fi
echo "OK"

# Step 2: Update lists
echo -n "Updating lists... "
if ! ./update_lists.sh >> "$LOG_FILE" 2>&1; then
    echo "FAILED!"
    exit 1
fi
echo "OK"

# Step 3: Optional - Update Gravity from remote sources
echo -n "Updating gravity... "
if ! pihole updateGravity >> "$LOG_FILE" 2>&1; then
    echo "FAILED!"
    exit 1
fi
echo "OK"

echo "=== Update Completed Successfully ==="
} | tee -a "$LOG_FILE"
