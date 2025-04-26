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
    
    while IFS= read -r line; do
        domain=$(echo "$line" | awk '{print $2}')
        if [[ -n "$domain" ]]; then
            echo "- $domain"
            if [[ "$list_type" == "allow" ]]; then
                pihole allow "$domain" --exact
            else
                pihole deny "$domain" --exact
            fi
        fi
    done < "$input_file"
}

echo "Allowlisting:"
add_to_list "allow" "$SCRIPT_DIR/top50_allowed.txt"

echo "Denylisting:"
add_to_list "deny" "$SCRIPT_DIR/top50_blocked.txt"

# Git versioning
if [ -d .git ]; then
    git add --all
    git commit -m "Update lists at $TIMESTAMP"
fi

# Update gravity
echo "Updating Pi-hole gravity..."
pihole updateGravity

echo "Update complete! Backup saved to $BACKUP_DIR"
