#!/bin/bash

# Get the script's directory (Git repo root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR" || exit 1

# Config
BACKUP_DIR="$SCRIPT_DIR/backups"
LOG_FILE="$SCRIPT_DIR/update.log"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_DIR"

{
    # Initialize counters
    NEW_ALLOWED=0
    NEW_BLOCKED=0
    REMOVED=0
    
    echo "=== Starting Pi-hole List Update ==="
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Get top domains for report
    TOP_ALLOWED=$(head -n 1 top50_allowed.txt 2>/dev/null || echo "0 unknown")
    TOP_BLOCKED=$(head -n 1 top50_blocked.txt 2>/dev/null || echo "0 unknown")
    
    echo -e "\n[Analysis Report]"
    echo "Top Allowed: $(echo $TOP_ALLOWED | awk '{print $2}') ($(echo $TOP_ALLOWED | awk '{print $1}') hits)"
    echo "Top Blocked: $(echo $TOP_BLOCKED | awk '{print $2}') ($(echo $TOP_BLOCKED | awk '{print $1}') hits)"
    
    # Backup current lists and count entries
    echo -e "\nBacking up current lists..."
    OLD_ALLOWED_COUNT=$(pihole allow --list | wc -l)
    OLD_BLOCKED_COUNT=$(pihole deny --list | wc -l)
    pihole allow --list > "$BACKUP_DIR/allowlist-$TIMESTAMP.txt"
    pihole deny --list > "$BACKUP_DIR/denylist-$TIMESTAMP.txt"
    
    # Clear existing entries
    echo -e "\nClearing previous dynamic entries..."
    REMOVED_ALLOWED=$(pihole allow --list | wc -l)
    REMOVED_BLOCKED=$(pihole deny --list | wc -l)
    pihole allow --all --exact -d >/dev/null
    pihole deny --all --exact -d >/dev/null
    REMOVED=$((REMOVED_ALLOWED + REMOVED_BLOCKED))
    
    # Add new entries
    echo -e "\nProcessing updates..."
    while IFS= read -r line; do
        domain=$(echo "$line" | awk '{print $2}')
        [ -n "$domain" ] && pihole allow "$domain" --exact >/dev/null && ((NEW_ALLOWED++))
    done < "top50_allowed.txt"
    
    while IFS= read -r line; do
        domain=$(echo "$line" | awk '{print $2}')
        [ -n "$domain" ] && pihole deny "$domain" --exact >/dev/null && ((NEW_BLOCKED++))
    done < "top50_blocked.txt"

    # Git versioning
    if [ -d .git ]; then
        git add --all
        git commit -m "Update lists at $TIMESTAMP"
    fi
    
    # Update gravity
    echo -e "\nUpdating gravity..."
    pihole updateGravity >/dev/null
    
    # Generate summary
    echo -e "\n[Update Summary]"
    [ $NEW_ALLOWED -gt 0 ] && echo "+ Whitelisted $NEW_ALLOWED new domains"
    [ $NEW_BLOCKED -gt 0 ] && echo "+ Blacklisted $NEW_BLOCKED new trackers"
    [ $REMOVED -gt 0 ] && echo "- Removed $REMOVED unused entries"
    
    echo -e "\n=== Update Completed Successfully ==="
    echo "Backups saved to: $BACKUP_DIR"
    echo "Detailed log: $LOG_FILE"
} | tee -a "$LOG_FILE"
