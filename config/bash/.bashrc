# ~/.bashrc

# NixOS flake directory
export FLAKE_DIR="${FLAKE_DIR:-$HOME/repos/nix-config}"
export PATH="$FLAKE_DIR/scripts:$PATH"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Auto-start tmux: attach to existing session or create a new one
if [ -z "$TMUX" ] && command -v tmux &>/dev/null; then
    exec tmux new-session -A -s main
fi

# History settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:ignorespace
shopt -s histappend

# Environment variables
export EDITOR='nvim'
export VISUAL='nvim'

# Alias definitions
alias vi='nvim'
alias vim='nvim'
alias v='nvim'
alias cat='bat -p'

# Directory listing aliases (using eza)
alias ls='eza'
alias ll='eza -alF'
alias la='eza -a'
alias l='eza -F'
alias lt='eza --tree --level=2'

# Navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Grep with color
alias grep='grep --color=auto'

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
alias lg='lazygit'

# Yazi with directory tracking
yazi_cd() {
    local tmp_file="/tmp/yazi-last-dir"
    command yazi --cwd-file="$tmp_file"
    if [ -f "$tmp_file" ]; then
        cd "$(cat "$tmp_file")" || return
    fi
}
alias yazi='yazi_cd'
alias r='yazi_cd'

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

# Add local bin to PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Function to parse Git branch
parse_git_branch() {
    local branch
    branch="$(git symbolic-ref HEAD 2>/dev/null)" || return
    echo " (${branch##refs/heads/})"
}

# Function to get exit status of last command
prompt_command() {
    EXIT_STATUS=$?
    history -a
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
