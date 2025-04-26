#!/bin/bash

# Pi-hole v5+ list locations
WHITELIST="/etc/pihole/whitelist.txt"
BLACKLIST="/etc/pihole/blacklist.txt"
GRAVITY_DB="/etc/pihole/gravity.db"

# Backup current lists with timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/root/pihole-dynamic-domains/backups"
mkdir -p "$BACKUP_DIR"

# Backup using pihole commands
pihole allow --list > "$BACKUP_DIR/whitelist-$TIMESTAMP.txt"
pihole deny --list > "$BACKUP_DIR/blacklist-$TIMESTAMP.txt"

# Clear existing lists using pihole commands
pihole allow --all --exact -d
pihole deny --all --exact -d

# Add new entries from analyzed files
add_to_list() {
    local list_type=$1
    local input_file=$2
    
    while IFS= read -r line; do
        domain=$(echo "$line" | awk '{print $2}')
        if [[ -n "$domain" ]]; then
            if [[ "$list_type" == "allow" ]]; then
                pihole allow "$domain" --exact
            else
                pihole deny "$domain" --exact
            fi
        fi
    done < "$input_file"
}

add_to_list "allow" "top50_allowed.txt"
add_to_list "deny" "top50_blocked.txt"

# Git versioning
if [ -d .git ]; then
    git add --all
    git commit -m "Auto-update: $(date +"%Y-%m-%d %H:%M")"
fi

# Update gravity
pihole updateGravity

echo "Lists updated:"
echo "- $(wc -l < top50_allowed.txt) domains allowlisted"
echo "- $(wc -l < top50_blocked.txt) domains denylisted"
echo "Backups saved to: $BACKUP_DIR"
