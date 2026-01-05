#!/bin/sh
# ============================================
# NIRI AUTOSTART SCRIPT
# ============================================

# ENVIRONMENT & DBUS
# ============================================
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
systemctl --user import-environment WAYLAND_DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP

# DISPLAY MANAGEMENT
# ============================================
# Monitors are configured natively in config.kdl (no need for way-displays)

# Helper function to start services cleanly
start_service() {
    local service=$1
    local command=$2
    pkill -x "$service" 2>/dev/null || true
    sleep 0.2
    eval "$command" &
}

# STATUS BAR
# ============================================
start_service waybar "sh ~/.config/waybar/launch-waybar.sh"

# NOTIFICATION DAEMON
# ============================================
start_service mako "mako"

# WALLPAPER
# ============================================
# Try multiple wallpaper locations in order
WALLPAPER_CANDIDATES=(
    "$HOME/Pictures/SierraLeone.jpg"
    "$HOME/Pictures/wallpaper.jpg"
    "$HOME/Pictures/wallpaper.png"
    "$HOME/.config/wallpaper.jpg"
    "$HOME/.config/wallpaper.png"
)

WALLPAPER=""
for wp in "${WALLPAPER_CANDIDATES[@]}"; do
    if [ -f "$wp" ]; then
        WALLPAPER="$wp"
        break
    fi
done

if [ -n "$WALLPAPER" ]; then
    pkill -x swww-daemon 2>/dev/null || true
    sleep 0.2
    swww-daemon &
    sleep 0.5
    swww img "$WALLPAPER" &
else
    notify-send "Wallpaper" "No wallpaper found in common locations" &
fi

# CLIPBOARD MANAGER
# ============================================
wl-paste --watch cliphist store &

# STARTUP VALIDATION
# ============================================
sleep 1.5
pgrep -x waybar >/dev/null || notify-send "Warning" "Waybar not running!" &
pgrep -x mako >/dev/null || notify-send "Warning" "Mako not running!" &

# LOG STARTUP
# ============================================
mkdir -p "$HOME/.local/state/niri"
echo "$(date): Niri started successfully" >> "$HOME/.local/state/niri/startup.log"
