#!/bin/sh
# Power menu for niri using wofi

OPTIONS="Lock\nSuspend\nLogout\nReboot\nShutdown"

CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Power")

case "$CHOICE" in
    Lock)
        waylock -init-color 0x002b36 -input-color 0x268bd2 -fail-color 0xdc322f
        ;;
    Suspend)
        systemctl suspend
        ;;
    Logout)
        niri msg action quit
        ;;
    Reboot)
        systemctl reboot
        ;;
    Shutdown)
        systemctl poweroff
        ;;
esac
