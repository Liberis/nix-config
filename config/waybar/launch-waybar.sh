#!/bin/sh
# Smart waybar launcher - detects compositor and loads appropriate config

# Kill any existing waybar instances
pkill -x waybar 2>/dev/null || true
sleep 0.2

# Detect which compositor is running
if [ -n "$SWAYSOCK" ]; then
    # Running Sway
    WAYBAR_CONFIG="$HOME/.config/waybar/config-sway"
    echo "Launching waybar for Sway"
elif [ -n "$NIRI_SOCKET" ]; then
    # Running Niri
    WAYBAR_CONFIG="$HOME/.config/waybar/config-niri"
    echo "Launching waybar for Niri"
elif pgrep -x niri >/dev/null 2>&1; then
    # Running Niri (fallback detection)
    WAYBAR_CONFIG="$HOME/.config/waybar/config-niri"
    echo "Launching waybar for Niri"
elif pgrep -x river >/dev/null 2>&1; then
    # Running River
    WAYBAR_CONFIG="$HOME/.config/waybar/config-river"
    echo "Launching waybar for River"
else
    # Fallback to River config
    WAYBAR_CONFIG="$HOME/.config/waybar/config-river"
    echo "Compositor not detected, using River config"
fi

# Launch waybar with the appropriate config
exec waybar -c "$WAYBAR_CONFIG" -s "$HOME/.config/waybar/style.css"
