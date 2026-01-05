#!/bin/sh
# Launch terminal on tag 1 and follow it there

# Switch to tag 1 first
riverctl set-focused-tags $((1 << 0))
# Then launch terminal (will open on current tag = tag 1)
foot &
