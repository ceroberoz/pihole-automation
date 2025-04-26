#!/bin/bash

# Get the script's directory (Git repo root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR" || exit 1

# Config
BACKUP_DIR="$SCRIPT_DIR/backups"
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Backup current lists
echo "Backing up current lists..."
pihole allow --list > "$BACKUP_DIR/allowlist-$TIMESTAMP.txt"
pihole deny --list > "$BACKUP_DIR/denylist-$TIMESTAMP.txt"

# Clear existing entries
echo "Clearing existing dynamic entries..."
pihole allow --all --exact -d
pihole deny --all --exact -d

# Add new entries
echo "Updating lists..."
add_to_list() {
    local list_type=$1
    local input_file=$2
    
    # Get total count for percentage calculation
    total=$(wc -l < "$input_file")
    current=0
    
    while IFS= read -r line; do
        domain=$(echo "$line" | awk '{print $2}')
        count=$(echo "$line" | awk '{print $1}')
        if [[ -n "$domain" ]]; then
            ((current++))
            progress=$((current * 100 / total))
            printf "\r[%3d%%] %-50s" "$progress" "$domain"
            if [[ "$list_type" == "allow" ]]; then
                pihole allow "$domain" --exact >/dev/null 2>&1
            else
                pihole deny "$domain" --exact >/dev/null 2>&1
            fi
        fi
    done < "$input_file"
    echo "" # New line after progress
}

echo -e "\nAllowlisting domains:"
add_to_list "allow" "$SCRIPT_DIR/top50_allowed.txt"

echo -e "\nDenylisting domains:"
add_to_list "deny" "$SCRIPT_DIR/top50_blocked.txt"

# Git versioning
if [ -d .git ]; then
    git add --all
    git commit -m "Update lists at $TIMESTAMP"
fi

# Update gravity
echo -e "\nUpdating Pi-hole gravity..."
pihole updateGravity

echo -e "\nUpdate complete! Backup saved to $BACKUP_DIR"
