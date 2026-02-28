#!/bin/sh
# ============================================
# NIRI AUTOSTART SCRIPT
# ============================================

# WAYLAND ENVIRONMENT
# ============================================
# Export Wayland vars to dbus/systemd immediately (these are ready now)
dbus-update-activation-environment --systemd WAYLAND_DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP
systemctl --user import-environment WAYLAND_DISPLAY NIRI_SOCKET XDG_SESSION_TYPE XDG_CURRENT_DESKTOP

# XWAYLAND SUPPORT
# ============================================
# Start xwayland-satellite for X11 app support (Steam, etc.)
pkill -x xwayland-satellite 2>/dev/null || true
sleep 0.2
xwayland-satellite :0 &

# Wait for the X11 socket to appear before exporting DISPLAY
i=0; while [ ! -e /tmp/.X11-unix/X0 ] && [ "$i" -lt 50 ]; do
    sleep 0.1; i=$((i + 1))
done

# Now export DISPLAY — the X server is actually accepting connections
dbus-update-activation-environment --systemd DISPLAY
systemctl --user import-environment DISPLAY

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
