#!/bin/sh
# Generic launcher: switch to tag, then launch app
# Usage: launch-app.sh <tag-number> <command>
#
# Example: launch-app.sh 3 "foot -e ncspot"  # Launch ncspot on tag 3

TAG_NUM="${1:-1}"
shift
COMMAND="$*"

if [ -z "$COMMAND" ]; then
    echo "Usage: $0 <tag-number> <command>"
    exit 1
fi

# Calculate tag bitmask (tag 1 = 1<<0, tag 2 = 1<<1, etc.)
TAG_MASK=$((1 << ($TAG_NUM - 1)))

# Switch to the target tag
riverctl set-focused-tags $TAG_MASK

# Launch the application
eval "$COMMAND" &
