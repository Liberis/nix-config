#!/bin/bash
# SSH host picker for tmux — reads from ~/.ssh/config
host=$(grep "^Host " ~/.ssh/config 2>/dev/null | grep -v '[*?]' | awk '{print $2}' | sort -u | fzf --prompt="SSH > " --height=100% --reverse)
[ -n "$host" ] && tmux new-window -n "$host" "ssh $host"
