# ~/.bashrc

# NixOS flake directory
export FLAKE_DIR="${FLAKE_DIR:-$HOME/repos/dotfiles/nix-flakes}"
export PATH="$FLAKE_DIR/scripts:$PATH"

# Tmux session management

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Enable bash completion if available
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

tmux_session() {
    SESSION_NAME="session"

    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        # Define windows in the format "window_name:command"
        # Leave command empty if you want a plain shell.
        windows=(
            "term:clear"
            "nvim:nvim"
            "yazi:yazi"
            "k8s:k9s"
            "logs:"
            "git:"
            "htop:htop"
            "azdotui:azdotui"
        )

    # Create the first window using new-session.
    IFS=':' read -r first_win first_cmd <<< "${windows[0]}"
    if [ -n "$first_cmd" ]; then
        tmux new-session -d -s "$SESSION_NAME" -n "$first_win" "$SHELL" -c "$first_cmd; clear; exec $SHELL"
    else
        tmux new-session -d -s "$SESSION_NAME" -n "$first_win"
    fi

    # Iterate over the remaining window definitions.
    for win in "${windows[@]:1}"; do
        IFS=':' read -r win_name win_cmd <<< "$win"
        if [ -n "$win_cmd" ]; then
            tmux new-window -t "$SESSION_NAME" -n "$win_name" "$SHELL" -c "$win_cmd; clear; exec $SHELL"
        else
            tmux new-window -t "$SESSION_NAME" -n "$win_name"
        fi
    done
    fi

    tmux select-window -t "$SESSION_NAME:term"
    tmux attach-session -t "$SESSION_NAME"
}



# History settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"

# Check if inside tmux, if not attach or start a session
# Environment variables
export EDITOR='nvim'
export VISUAL='nvim'


# Alias definitions
alias vi='nvim'
alias vim='nvim'
alias v='nvim'
alias cat='bat -p'
alias r='ranger'

# Pacman aliases
#alias pacman='sudo pacman'
#alias update='sudo pacman -Syu'
#alias install='sudo pacman -S'
#alias remove='sudo pacman -Rns'
#alias search='pacman -Ss'

# Yay (AUR helper) aliases
#alias yay='yay'
#alias aurinstall='yay -S'
#alias aurremove='yay -Rns'
#alias aursearch='yay -Ss'

# Directory listing aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Grep with color
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Docker aliases
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dexec='docker exec -it'
alias dlogs='docker logs -f'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kdn='kubectl describe node'

# Git aliases
alias ga='git add'
alias gb='git branch'
alias gbd='git branch -D'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gl='git pull'
alias gp='git push'
alias gst='git status'
alias gss='git status -s'
alias gcl='git clone'

# Tmux alias
alias tmux='tmux_session'
alias t='tmux'
alias ranger='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`cat $HOME/.rangerdir`; cd "$LASTDIR"'
yazi_cd() {
    local tmp_file="/tmp/yazi-last-dir"
    yazi --cwd-file="$tmp_file"
    if [ -f "$tmp_file" ]; then
        cd "$(cat "$tmp_file")" || return
    fi
}
alias yazi=yazi_cd
alias ranger=yazi_cd
# Function to extract archives
extract() {
    if [ -f "$1" ] ; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Function to make directory and change into it
mcd () {
    mkdir -p "$1" && cd "$1";
}

# Enable colors for ls and grep
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Add local bin to PATH if needed
export PATH="$HOME/.local/bin:/home/liberis/.cargo/bin:$PATH"
# Function to parse Git branch
parse_git_branch() {
    local branch
    branch="$(git symbolic-ref HEAD 2>/dev/null)" || return
    echo " (${branch##refs/heads/})"
}

# Function to get exit status of last command
prompt_command() {
    EXIT_STATUS=$?
}

PROMPT_COMMAND=prompt_command

# Enhanced Prompt
PS1=''

# Color codes
RESET="\[\e[0m\]"
BOLD="\[\e[1m\]"
RED="\[\e[0;31m\]"
GREEN="\[\e[0;32m\]"
YELLOW="\[\e[0;33m\]"
BLUE="\[\e[0;34m\]"
MAGENTA="\[\e[0;35m\]"
CYAN="\[\e[0;36m\]"
WHITE="\[\e[0;37m\]"


# Construct the prompt
PS1+="${BOLD}${GREEN}\u@\h "            # Username@Hostname
PS1+="${YELLOW}\w"                      # Current Directory

# Exit status
PS1+='$(if [[ $EXIT_STATUS != 0 ]]; then echo "'"${RED}"' ✗"; else echo "'"${GREEN}"' ✔"; fi)'

# Git branch
PS1+="${MAGENTA}\$(parse_git_branch)"

# New line and prompt symbol
PS1+="\n${WHITE}\\$ ${RESET}"

# Export the PS1
export PS1
