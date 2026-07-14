#!/usr/bin/env bash
# Dotfiles installer, profile-aware.
#
# Usage:
#   ./install.sh [profile]
#
# Profiles:
#   desktop  Studios / always-on Macs   common + design + dev + personal + desktop
#   laptop   personal laptop, Mac Mini  common + design + dev + personal
#   work     work laptop                common + design + dev   (work git identity, no personal media)
#   server   Linux / headless           delegates to server/bootstrap.sh
#
# Profile resolution order: argument > saved ~/.dotfiles-profile > interactive prompt.
# The chosen profile is saved so re-running with no argument just repeats it.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
OS="$(uname)"
PROFILE_FILE="$HOME/.dotfiles-profile"

# --- Resolve profile --------------------------------------------------------
PROFILE="${1:-}"
if [ -z "$PROFILE" ] && [ -f "$PROFILE_FILE" ]; then
  PROFILE="$(cat "$PROFILE_FILE")"
fi
if [ -z "$PROFILE" ]; then
  echo "Select a profile:"
  echo "  1) desktop  — Studios / always-on Macs (everything)"
  echo "  2) laptop   — personal laptop, Mac Mini (design + dev + personal)"
  echo "  3) work     — work laptop (design + dev, work git identity, no personal media)"
  echo "  4) server   — Linux / headless (bootstrap + hardening)"
  read -rp "Profile [1-4]: " choice
  case "$choice" in
    1) PROFILE=desktop ;;
    2) PROFILE=laptop ;;
    3) PROFILE=work ;;
    4) PROFILE=server ;;
    *) echo "Unknown choice."; exit 1 ;;
  esac
fi
case "$PROFILE" in
  desktop|laptop|work|server) ;;
  *) echo "Unknown profile: $PROFILE"; exit 1 ;;
esac
echo "$PROFILE" > "$PROFILE_FILE"
echo "==> Profile: $PROFILE"

# --- Server profile delegates to the Linux bootstrap ------------------------
if [ "$PROFILE" = "server" ]; then
  exec bash "$DOTFILES/server/bootstrap.sh"
fi

# --- Symlink helper ---------------------------------------------------------
link() {
  local src="$DOTFILES/$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mkdir -p "$BACKUP"
    mv "$dest" "$BACKUP/"
    echo "backed up existing $dest -> $BACKUP/"
  fi
  ln -sfn "$src" "$dest"
  echo "linked $dest"
}

# --- Shell + git (every Mac profile) ----------------------------------------
link zsh/zshrc            "$HOME/.zshrc"
link zsh/zprofile         "$HOME/.zprofile"
link zsh/aliases.zsh      "$HOME/.aliases.zsh"
link config/starship.toml "$HOME/.config/starship.toml"
link git/gitconfig        "$HOME/.gitconfig"
link git/gitignore_global "$HOME/.gitignore_global"

# --- Work git identity: prompt once, write ~/.gitconfig.work ----------------
# The includeIf in .gitconfig applies this to repos under ~/work/.
if [ "$PROFILE" = "work" ]; then
  WORK_GIT="$HOME/.gitconfig.work"
  if [ ! -f "$WORK_GIT" ] || grep -q "CHANGE-ME" "$WORK_GIT" 2>/dev/null; then
    email="${WORK_EMAIL:-}"
    if [ -z "$email" ]; then
      read -rp "Work git email (for repos under ~/work/): " email
    fi
    if [ -n "$email" ]; then
      printf '# Work identity — applied to repos under ~/work/ (see includeIf in .gitconfig).\n[user]\n\temail = %s\n' "$email" > "$WORK_GIT"
      chmod 600 "$WORK_GIT"
      echo "wrote work git identity ($email) to $WORK_GIT"
    else
      echo "no work email entered; skipping (edit $WORK_GIT later)"
    fi
  else
    echo "work git identity already set in $WORK_GIT (leaving as-is)"
  fi
fi

# --- SSH client config (macOS only; the config uses macOS-only options) -----
if [ "$OS" = "Darwin" ]; then
  mkdir -p "$HOME/.ssh/sockets"
  chmod 700 "$HOME/.ssh"
  # Preserve existing hosts: on first run, migrate the current ~/.ssh/config
  # into config.local so the Include keeps them. Never clobbers your hosts.
  if [ ! -f "$HOME/.ssh/config.local" ]; then
    if [ -f "$HOME/.ssh/config" ] && [ ! -L "$HOME/.ssh/config" ]; then
      cp "$HOME/.ssh/config" "$HOME/.ssh/config.local"
      echo "migrated your existing SSH hosts into $HOME/.ssh/config.local"
    else
      cp "$DOTFILES/ssh/config.local.example" "$HOME/.ssh/config.local"
      echo "created $HOME/.ssh/config.local from the template"
    fi
    chmod 600 "$HOME/.ssh/config.local"
  fi
  link ssh/config "$HOME/.ssh/config"
  chmod 600 "$DOTFILES/ssh/config"
fi

# --- macOS package install --------------------------------------------------
if [ "$OS" != "Darwin" ]; then
  echo "Non-macOS host with a desktop/laptop/work profile; skipping Homebrew apps."
  exit 0
fi
if ! command -v brew >/dev/null; then
  echo "Homebrew not found. Install it first:"
  echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

# Tolerate per-app failures (already-installed apps, license sign-ins) so one
# hiccup doesn't abort the whole run under `set -e`.
bundle() {
  echo "==> brew bundle: $1"
  brew bundle --file="$DOTFILES/$1" \
    || echo "!!  some entries in $1 need attention (see above); continuing"
}
cask_install() {
  echo "==> brew install --cask $1"
  brew install --cask "$1" || echo "!!  $1 needs attention (see above); continuing"
}

bundle Brewfile                                   # common, always
case "$PROFILE" in
  work)
    bundle brew/design.Brewfile
    bundle brew/dev.Brewfile
    ;;
  laptop)
    bundle brew/design.Brewfile
    bundle brew/dev.Brewfile
    bundle brew/personal.Brewfile
    ;;
  desktop)
    bundle brew/design.Brewfile
    bundle brew/dev.Brewfile
    bundle brew/personal.Brewfile
    bundle brew/desktop.Brewfile
    ;;
esac

# Work comms: pick which chat/meeting apps to install (asked once, remembered).
if [ "$PROFILE" = "work" ]; then
  COMMS_FILE="$HOME/.dotfiles-work-comms"
  if [ -f "$COMMS_FILE" ]; then
    comms="$(cat "$COMMS_FILE")"
  else
    comms="${WORK_COMMS:-}"
    if [ -z "$comms" ]; then
      echo ""
      echo "Which comms apps for the work machine?"
      echo "  options: slack zoom teams telegram  (space-separated, or 'all' / 'none')"
      read -rp "> " comms
    fi
    [ "$comms" = "all" ]  && comms="slack zoom teams telegram"
    [ "$comms" = "none" ] && comms=""
    echo "$comms" > "$COMMS_FILE"
  fi
  for app in $comms; do
    case "$app" in
      slack)    cask_install slack ;;
      zoom)     cask_install zoom ;;
      teams)    cask_install microsoft-teams ;;
      telegram) cask_install telegram ;;
      *) echo "unknown comms app: $app (skipping)" ;;
    esac
  done
fi

echo ""
echo "Done. Profile '$PROFILE' installed. Open a new terminal (or run: exec zsh)."
echo "Optional: ./macos/defaults.sh to apply system preferences."
