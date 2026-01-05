#!/bin/sh
# Run-or-raise script for Sway WM
# Usage: run-or-raise.sh <app-id> <command> [process-name]

APP_ID="$1"
COMMAND="$2"
PROCESS_NAME="${3:-$APP_ID}"

if [ -z "$APP_ID" ] || [ -z "$COMMAND" ]; then
    echo "Usage: $0 <app-id> <command> [process-name]"
    exit 1
fi

# Check if swaymsg is available
if ! command -v swaymsg >/dev/null 2>&1; then
    echo "Error: swaymsg not found"
    exit 1
fi

# Check if the application is already running by querying sway's window tree
if swaymsg -t get_tree | jq -e ".. | select(.app_id? == \"$APP_ID\")" > /dev/null 2>&1; then
    # Application is running - focus it
    swaymsg "[app_id=\"$APP_ID\"] focus"
    exit 0
fi

# Application not found, launch it
eval "$COMMAND" &
