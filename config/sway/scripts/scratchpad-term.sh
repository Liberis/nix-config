#!/bin/sh
# Scratchpad terminal for Sway
# Creates or shows a floating terminal as scratchpad

# Check if scratchpad window exists
if swaymsg -t get_tree | jq -e '.. | select(.app_id? == "scratchpad")' > /dev/null 2>&1; then
    # Window exists, show it
    swaymsg '[app_id="scratchpad"] scratchpad show'
else
    # Create new scratchpad terminal
    foot -a scratchpad &
    sleep 0.2
    swaymsg '[app_id="scratchpad"] move scratchpad, scratchpad show'
fi
