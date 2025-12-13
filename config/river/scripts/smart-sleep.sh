#!/bin/sh
# Smart screen off - locks and turns off screens only if no media is playing

# Check if media is playing
if sh ~/.config/river/scripts/check-media-playing.sh; then
    # Media is playing, notify and skip
    notify-send "Screen Off Cancelled" "Media is currently playing"
    exit 0
fi

# No media playing, lock and turn off screens
waylock -init-color 0x002b36 -input-color 0x268bd2 -fail-color 0xdc322f &
sleep 0.5

# Turn off all monitors
MONITORS=$(wlr-randr | grep "^[A-Z]" | awk '{print $1}')
for mon in $MONITORS; do
    wlr-randr --output "$mon" --off
    wlopm --off "$mon"
done
