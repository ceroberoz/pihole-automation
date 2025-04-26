#!/bin/bash

# Get the script's directory (Git repo root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LOG_FILE="$SCRIPT_DIR/update.log"

{
    echo "=== Pi-hole Dynamic List Update $(date) ==="
    cd "$SCRIPT_DIR" || exit 1
    
    echo "Step 1: Analyzing traffic..."
    if ! ./analyze_pihole_logs.sh; then
        echo "Analysis failed!"
        exit 1
    fi
    
    echo "Step 2: Updating lists..."
    if ! ./update_lists.sh; then
        echo "Update failed!"
        exit 1
    fi
    
    echo "=== Update completed successfully ==="
} | tee -a "$LOG_FILE"
