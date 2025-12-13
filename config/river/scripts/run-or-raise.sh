#!/bin/sh
# Run-or-raise with move functionality for River WM
# Usage: run-or-raise.sh <app-id> <command> [process-name]

APP_ID="$1"
COMMAND="$2"
PROCESS_NAME="${3:-$APP_ID}"

if [ -z "$APP_ID" ] || [ -z "$COMMAND" ]; then
    echo "Usage: $0 <app-id> <command> [process-name]"
    exit 1
fi

# Check if wlrctl is available for advanced window management
if ! command -v wlrctl >/dev/null 2>&1; then
    # Fallback: simple run-or-raise without move functionality
    if ! pgrep -x "$PROCESS_NAME" >/dev/null 2>&1; then
        eval "$COMMAND" &
    fi
    exit 0
fi

# Check if the application is already running
if ! pgrep -x "$PROCESS_NAME" >/dev/null 2>&1; then
    # Not running, launch it
    eval "$COMMAND" &
    exit 0
fi

# Application is running - find and focus it
# Get the window with matching app_id
WINDOW=$(wlrctl window find app_id:"$APP_ID" 2>/dev/null | head -n1)

if [ -z "$WINDOW" ]; then
    # Window not found, might be already closed or different app_id
    # Launch a new instance
    eval "$COMMAND" &
    exit 0
fi

# Focus the window (this will also move it to current output if configured)
wlrctl window focus "$WINDOW"

# Optionally: Move window to current output
# Get current output
CURRENT_OUTPUT=$(wlrctl output find focused 2>/dev/null | head -n1)

if [ -n "$CURRENT_OUTPUT" ]; then
    # Move window to current output
    wlrctl window move "$WINDOW" "$CURRENT_OUTPUT" 2>/dev/null || true
fi

# Focus again to ensure it's active
wlrctl window focus "$WINDOW" 2>/dev/null || true
