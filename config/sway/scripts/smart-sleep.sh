#!/bin/sh
# Smart sleep script for Sway
# Locks screen then suspends system

# Lock the screen first
waylock -init-color 0x002b36 -input-color 0x268bd2 -fail-color 0xdc322f &

# Wait a moment for waylock to initialize
sleep 1

# Suspend the system
systemctl suspend
