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
    echo "=== Starting Pi-hole List Update ==="
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Backup current lists
    echo -n "Backing up current lists... "
    pihole allow --list > "$BACKUP_DIR/allowlist-$TIMESTAMP.txt"
    pihole deny --list > "$BACKUP_DIR/denylist-$TIMESTAMP.txt"
    echo "Done"
    
    # Clear existing entries
    echo -n "Clearing previous dynamic entries... "
    pihole allow --all --exact -d >/dev/null
    pihole deny --all --exact -d >/dev/null
    echo "Done"
    
    # Add new entries with progress
    process_domains() {
        local list_type=$1
        local input_file=$2
        local total=$(wc -l < "$input_file")
        local count=0
        local last_reported=0
        
        echo -n "Updating ${list_type}list: "
        
        while IFS= read -r domain; do
            ((count++))
            progress=$((count * 100 / total))
            
            # Only show progress every 10% or for the last item
            if (( progress >= last_reported + 10 )) || (( count == total )); then
                echo -n "${progress}% "
                last_reported=$progress
            fi
            
            if [[ "$list_type" == "allow" ]]; then
                pihole allow "$domain" --exact >/dev/null
            else
                pihole deny "$domain" --exact >/dev/null
            fi
        done < <(awk '{print $2}' "$input_file")
        echo "" # New line after progress
    }
    
    # Process lists
    [[ -f "top50_allowed.txt" ]] && process_domains "allow" "top50_allowed.txt"
    [[ -f "top50_blocked.txt" ]] && process_domains "deny" "top50_blocked.txt"
   
    # Git versioning
    if [ -d .git ]; then
        git add --all
        git commit -m "Update lists at $TIMESTAMP"
    fi

    # Update gravity
    echo -n "Updating gravity... "
    pihole updateGravity >/dev/null
    echo "Done"
    
    echo "=== Update Completed Successfully ==="
    echo "Backups saved to: $BACKUP_DIR"
    echo "Detailed log: $LOG_FILE"
} | tee -a "$LOG_FILE"
