#!/bin/sh
# Generic launcher: switch to workspace, then launch app
# Usage: launch-app.sh <workspace> <command>
#
# Example: launch-app.sh "3:music" "foot -e ncspot"

WORKSPACE="${1}"
shift
COMMAND="$*"

if [ -z "$COMMAND" ]; then
    echo "Usage: $0 <workspace> <command>"
    exit 1
fi

# Switch to the target workspace
swaymsg workspace "$WORKSPACE"

# Launch the application
eval "$COMMAND" &
