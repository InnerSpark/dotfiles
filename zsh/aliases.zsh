# ~/.aliases.zsh
# Shared across macOS and Linux servers. OS-specific bits are guarded at the
# bottom so nothing broken gets defined on the wrong platform.

# --- Listing (eza if installed, plain ls fallback) ---------------------------
if command -v eza >/dev/null; then
  alias ls='eza --icons'
  alias ll='eza -la --icons --git'
  alias la='eza -a --icons'
  alias lt='eza -la --icons --sort=modified'
  alias tree='eza --tree --icons'
else
  if [[ "$OSTYPE" == darwin* ]]; then
    alias ls='ls -G'
  else
    alias ls='ls --color=auto'
  fi
  alias ll='ls -al'
  alias la='ls -AF'
fi
alias l.='ls -d .*'

# --- Navigation --------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'
alias md='mkdir -p'
alias rd='rmdir'
alias q='exit'
alias cls='clear'
alias h='history'
alias reload='source ~/.zshrc'

# Allow aliases after sudo
alias sudo='sudo '

# --- Git ---------------------------------------------------------------------
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcm='git commit -v -m'
alias gca='git commit -v -a'
alias amend='git commit --amend'
alias gco='git checkout'
alias gb='git branch'
alias gba='git branch -a'
alias gdel='git branch -D'
alias gd='git diff'
alias gdc='git diff --cached'
alias wdiff='git diff --word-diff'
alias gl='git pull'
alias gpr='git pull --rebase'
alias gp='git push'
alias gcl='git clone'
alias gcp='git cherry-pick'
alias gus='git reset HEAD'
alias gg="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias glo='git log --oneline --decorate'
alias gt='cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"'
alias wip='git add -A && git commit -m "wip"'
alias unwip='git log -n 1 --pretty=%s | grep -q wip && git reset HEAD~1'

# --- GitHub CLI -----------------------------------------------------------
alias ghpr='gh pr create --web'
alias ghprs='gh pr status'
alias ghv='gh repo view --web'

# --- Homebrew (macOS, or Linuxbrew if present) ------------------------------
if command -v brew >/dev/null; then
  alias bup='brew update && brew upgrade && brew cleanup'
  alias bout='brew outdated'
  alias bin='brew install'
  alias brm='brew uninstall'
  alias bls='brew list'
  alias bsr='brew search'
  alias binf='brew info'
  alias bdr='brew doctor'
fi

# --- Docker --------------------------------------------------------------------
alias dl='docker ps -l -q'
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dip='docker inspect --format "{{ .NetworkSettings.IPAddress }}"'
alias dkd='docker run -d -P'
alias dki='docker run -i -t -P'
alias drmf='docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)'
dstop() { if [ $# -eq 0 ]; then docker stop $(docker ps -a -q); else docker stop "$@"; fi; }
drm()   { if [ $# -eq 0 ]; then docker rm  $(docker ps -a -q); else docker rm  "$@"; fi; }
dri()   { if [ $# -eq 0 ]; then docker image prune -f; else docker rmi "$@"; fi; }
dent()  { docker exec -i -t "$1" /bin/bash; }
dbash() { docker run --rm -i -t -e TERM=xterm --entrypoint /bin/bash "$1"; }
dbu()   { docker build -t "$1" .; }

# --- macOS-only --------------------------------------------------------------
if [[ "$OSTYPE" == darwin* ]]; then
  alias of='open -a Finder ./'
  alias ql='qlmanage -p'
  alias dsclean='find . -type f -name .DS_Store -delete'
  alias ip='dig +short myip.opendns.com @resolver1.opendns.com'
  alias localip='ipconfig getifaddr en0'
  alias flushdns='dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
  alias pubkey='pbcopy < ~/.ssh/id_ed25519.pub && echo "=> Public key copied to pasteboard."'
  alias showdotfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
  alias hidedotfiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
  alias showdeskicons='defaults write com.apple.finder CreateDesktop -bool true && killall Finder'
  alias hidedeskicons='defaults write com.apple.finder CreateDesktop -bool false && killall Finder'
fi

# --- Linux-only --------------------------------------------------------------
if [[ "$OSTYPE" == linux* ]]; then
  command -v xdg-open >/dev/null && alias open='xdg-open'
  # Debian ships these under different names
  command -v batcat  >/dev/null && alias bat='batcat'
  command -v fdfind  >/dev/null && alias fd='fdfind'
  alias ip='hostname -I 2>/dev/null | awk "{print \$1}"'
  alias ports='ss -tulpn'
  alias myip='curl -s ifconfig.me; echo'
fi
