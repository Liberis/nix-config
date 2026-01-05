#!/bin/sh
# Smart lock - only locks if no media is playing

# Check if media is playing
if sh ~/.config/river/scripts/check-media-playing.sh; then
    # Media is playing, skip locking
    exit 0
fi

# No media playing, proceed with lock
waylock -init-color 0x002b36 -input-color 0x268bd2 -fail-color 0xdc322f
