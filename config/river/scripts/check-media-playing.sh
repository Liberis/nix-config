#!/bin/sh
# Check if any media is currently playing via playerctl
# Returns 0 if playing, 1 if not

if command -v playerctl >/dev/null 2>&1; then
    STATUS=$(playerctl status 2>/dev/null)
    if [ "$STATUS" = "Playing" ]; then
        exit 0
    fi
fi

exit 1
