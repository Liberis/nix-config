#!/bin/sh
# Smart lock script for Sway
# Checks if media is playing before locking

# Check if any media is playing
if playerctl status 2>/dev/null | grep -q "Playing"; then
    echo "Media is playing, skipping lock"
    exit 0
fi

# No media playing, lock the screen
waylock -init-color 0x002b36 -input-color 0x268bd2 -fail-color 0xdc322f
