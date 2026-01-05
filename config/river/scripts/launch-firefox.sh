#!/bin/sh
# Launch Firefox on tag 2 and follow it there

# Check if Firefox is already running
if pgrep -x firefox >/dev/null; then
    # Firefox exists, just switch to tag 2
    riverctl set-focused-tags $((1 << 1))
else
    # Switch to tag 2 first
    riverctl set-focused-tags $((1 << 1))
    # Then launch Firefox (will open on current tag = tag 2)
    firefox &
fi
