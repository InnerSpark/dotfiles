#!/usr/bin/env bash
# Spark dotfiles installer — profile-aware, with first-run machine setup.
#
# Usage:
#   ./install.sh [profile] [--dry-run] [--reconfigure]
#
# Profiles:
#   desktop  Studios / always-on Macs   common + design + dev + personal + desktop
#   laptop   personal laptop, Mac Mini  common + design + dev + personal
#   work     work laptop                common + design + dev (work git identity)
#   server   Linux / headless           delegates to server/bootstrap.sh
#
# Flags:
#   --dry-run       show what would happen, change nothing
#   --reconfigure   re-run the optional machine-setup questions

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
OS="$(uname)"
PROFILE_FILE="$HOME/.dotfiles-profile"
SETUP_MARKER="$HOME/.dotfiles-setup-done"

# --- Args -------------------------------------------------------------------
PROFILE=""; DRY_RUN=0; RECONFIGURE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --reconfigure) RECONFIGURE=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown flag: $1"; exit 1 ;;
    *) PROFILE="$1" ;;
  esac
  shift
done

# --- Colors + UI ------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD=$'\e[1m'; RESET=$'\e[0m'; MUTED=$'\e[38;5;244m'
  PEACH=$'\e[38;2;250;179;135m'; SKY=$'\e[38;2;137;180;250m'; GREEN=$'\e[38;2;166;227;161m'
  B1=$'\e[38;2;74;168;224m'; B2=$'\e[38;2;32;128;192m'; B3=$'\e[38;2;0;112;176m'
else
  BOLD=; RESET=; MUTED=; PEACH=; SKY=; GREEN=; B1=; B2=; B3=
fi

hr()    { printf '%s   ────────────────────────────────────────────%s\n' "$MUTED" "$RESET"; }
head2() { printf '\n%s?%s %s%s%s\n' "$PEACH" "$RESET" "$BOLD" "$1" "$RESET"; }
note()  { printf '   %s%s%s\n' "$MUTED" "$1" "$RESET"; }
ok()    { printf '   %s✓%s %s\n' "$GREEN" "$RESET" "$1"; }

# y/N (or Y/n) prompt read from the terminal even if stdin is piped.
ask_yn() {
  local q="$1" def="${2:-n}" p ans
  [ "$def" = y ] && p="[Y/n]" || p="[y/N]"
  if [ -r /dev/tty ]; then
    read -rp "$(printf '%s?%s %s %s%s%s ' "$PEACH" "$RESET" "$q" "$MUTED" "$p" "$RESET")" ans </dev/tty || ans=""
  else ans=""; fi
  ans="${ans:-$def}"; [[ "$ans" =~ ^[Yy] ]]
}
ask() {  # $1 prompt -> echoes answer
  local q="$1" ans
  if [ -r /dev/tty ]; then
    read -rp "$(printf '%s›%s %s ' "$SKY" "$RESET" "$q")" ans </dev/tty || ans=""
  fi
  printf '%s' "$ans"
}

banner() {
  [ -n "${NO_LOGO:-}" ] && return
  printf '\n'
  printf '%s\n' "$B1"'                         ⣴⣿⡄
                        ⢸⣿⣿
                        ⢸⡿⠁
                        ⣿⠃
         ⢠⡀            ⢰⡏
         ⢻⣿     ⢸⡇     ⣼⠁
         ⠘⣿⡆    ⣼⣧    ⢠⠇'"$RESET"
  printf '%s\n' "$B2"'          ⠸⡆    ⣿⣿    ⡜        ⣠⣾⠇
     ⢢     ⠃   ⢰⣿⣿⡆   ⠁    ⡄  ⣰⣿⠋
      ⢳⡀       ⣸⡿⢿⣇       ⡜  ⢠⠏⠁
       ⠱⡄      ⣿⡇⢸⣿      ⡼⠁ ⡰⠁
⠠⡀      ⠹⣄    ⢰⣿⡇⢸⣿⡆    ⣼⠁      ⢀⠄
 ⠘⢷⣤⣀    ⠹⣆   ⣸⣿⠃⠘⣿⣇   ⣼⠃    ⣀⣴⡾⠃
   ⠙⣿⣷⣦⣀  ⠹⣧ ⣀⠿⠟⢠⡄⠻⠿⣀ ⣼⠇  ⣀⣴⣾⣿⠋'"$RESET"
  printf '%s\n' "$B3"'    ⠈⠻⣎⠻⣷⣦⣀⣿⠋⠁  ⣸⡇  ⠈⠻⣯⣀⣴⣾⠟⣱⠟⠁
      ⠹⣷⡈⠛⠿⠁   ⢀⣿⣷    ⠈⠿⠋⢁⣾⠋
       ⠹⣿⣆    ⢀⣾⣿⣿⣷⡀    ⣰⣿⠇
        ⢿⣿   ⣴⣿⣿⣿⣿⣿⣿⣦   ⣿⡿
        ⢸⣿  ⢸⣿⣿⣿⣿⣿⣿⣿⣿⡆ ⢀⣿⡇
         ⢻⣇ ⠘⣿⣿⣿⣿⣿⣿⣿⣿⠁ ⣸⡟
          ⠻⣦ ⠘⢿⣿⣿⣿⣿⡿⠃⢀⣴⠟
            ⠑⠢ ⠈⠉⠉⠁ ⠔⠋'"$RESET"
  printf '\n      %sSPARK%s  %sdotfiles%s\n' "$BOLD" "$RESET" "$MUTED" "$RESET"
}

banner

# --- Resolve profile --------------------------------------------------------
if [ -z "$PROFILE" ] && [ -f "$PROFILE_FILE" ]; then PROFILE="$(cat "$PROFILE_FILE")"; fi
if [ -z "$PROFILE" ]; then
  head2 "Which profile is this machine?"
  printf '   %s1%s desktop  %sStudios — everything%s\n'                 "$SKY" "$RESET" "$MUTED" "$RESET"
  printf '   %s2%s laptop   %spersonal MacBook, Mac Mini%s\n'           "$SKY" "$RESET" "$MUTED" "$RESET"
  printf '   %s3%s work     %swork MacBook — no personal media%s\n'     "$SKY" "$RESET" "$MUTED" "$RESET"
  printf '   %s4%s server   %sLinux — bootstrap + hardening%s\n'        "$SKY" "$RESET" "$MUTED" "$RESET"
  choice="$(ask 'Profile [1-4]:')"
  case "$choice" in
    1) PROFILE=desktop ;; 2) PROFILE=laptop ;; 3) PROFILE=work ;; 4) PROFILE=server ;;
    *) echo "Unknown choice."; exit 1 ;;
  esac
fi
case "$PROFILE" in desktop|laptop|work|server) ;; *) echo "Unknown profile: $PROFILE"; exit 1 ;; esac

# --- Dry run: print the plan and stop ---------------------------------------
if [ "$DRY_RUN" = 1 ]; then
  hr; note "DRY RUN — profile: $PROFILE. Nothing will change."
  note "symlink: zshrc, zprofile, aliases.zsh, starship.toml, gitconfig, gitignore_global"
  case "$PROFILE" in
    server) note "run: server/bootstrap.sh (packages + hardening)" ;;
    work)    note "brew: Brewfile + design + dev; prompt: git email, comms" ;;
    laptop)  note "brew: Brewfile + design + dev + personal" ;;
    desktop) note "brew: Brewfile + design + dev + personal + desktop" ;;
  esac
  note "optional setup: 1Password agent, gh auth, SSH key, commit signing,"
  note "                editor, Node LTS, computer name, iTerm2, macOS defaults"
  exit 0
fi

echo "$PROFILE" > "$PROFILE_FILE"
printf '\n'; ok "profile: $BOLD$PROFILE$RESET"

# --- Server profile delegates to the Linux bootstrap ------------------------
if [ "$PROFILE" = "server" ]; then exec bash "$DOTFILES/server/bootstrap.sh"; fi

# --- Symlink helper ---------------------------------------------------------
link() {
  local src="$DOTFILES/$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then mkdir -p "$BACKUP"; mv "$dest" "$BACKUP/"; fi
  ln -sfn "$src" "$dest"
}

link zsh/zshrc            "$HOME/.zshrc"
link zsh/zprofile         "$HOME/.zprofile"
link zsh/aliases.zsh      "$HOME/.aliases.zsh"
link config/starship.toml "$HOME/.config/starship.toml"
link git/gitconfig        "$HOME/.gitconfig"
link git/gitignore_global "$HOME/.gitignore_global"
ok "shell + git config linked"

# --- Work git identity ------------------------------------------------------
if [ "$PROFILE" = "work" ]; then
  WORK_GIT="$HOME/.gitconfig.work"
  if [ ! -f "$WORK_GIT" ] || grep -q "CHANGE-ME" "$WORK_GIT" 2>/dev/null; then
    head2 "Work git email (for repos under ~/work/)"
    email="${WORK_EMAIL:-$(ask 'email:')}"
    if [ -n "$email" ]; then
      printf '# Work identity — repos under ~/work/ (see includeIf in .gitconfig).\n[user]\n\temail = %s\n' "$email" > "$WORK_GIT"
      chmod 600 "$WORK_GIT"; ok "work identity: $email"
    fi
  fi
fi

# --- SSH client config (macOS) ----------------------------------------------
if [ "$OS" = "Darwin" ]; then
  mkdir -p "$HOME/.ssh/sockets"; chmod 700 "$HOME/.ssh"
  if [ ! -f "$HOME/.ssh/config.local" ]; then
    if [ -f "$HOME/.ssh/config" ] && [ ! -L "$HOME/.ssh/config" ]; then
      cp "$HOME/.ssh/config" "$HOME/.ssh/config.local"; ok "migrated existing SSH hosts to config.local"
    else cp "$DOTFILES/ssh/config.local.example" "$HOME/.ssh/config.local"; fi
    chmod 600 "$HOME/.ssh/config.local"
  fi
  link ssh/config "$HOME/.ssh/config"; chmod 600 "$DOTFILES/ssh/config"
fi

# --- Homebrew packages ------------------------------------------------------
if [ "$OS" != "Darwin" ]; then
  note "Non-macOS host with a Mac profile; skipping Homebrew apps."; exit 0
fi
if ! command -v brew >/dev/null; then
  head2 "Homebrew not found — installing it"
  note "you may be asked for your password (Homebrew needs sudo to set up)"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || { echo "Homebrew install failed (network?). Install it manually and re-run."; exit 1; }
  # Put brew on PATH for the rest of this run (zprofile handles future shells).
  if   [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew   ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
  if command -v brew >/dev/null; then ok "Homebrew installed"
  else echo "brew still not on PATH — open a new terminal and re-run install."; exit 1; fi
fi

bundle() {
  printf '\n%s==>%s brew bundle: %s\n' "$SKY" "$RESET" "$1"
  brew bundle --file="$DOTFILES/$1" || note "some entries in $1 need attention; continuing"
}
cask_install() {
  brew install --cask "$1" || note "$1 needs attention; continuing"
}

bundle Brewfile
case "$PROFILE" in
  work)    : ;;   # work picks its apps interactively below
  laptop)  bundle brew/design.Brewfile; bundle brew/dev.Brewfile; bundle brew/personal.Brewfile ;;
  desktop) bundle brew/design.Brewfile; bundle brew/dev.Brewfile; bundle brew/personal.Brewfile; bundle brew/desktop.Brewfile ;;
esac

# Work profile: pick which design/dev apps to install (asked once, remembered).
if [ "$PROFILE" = "work" ]; then
  APPS_FILE="$HOME/.dotfiles-work-apps"
  if [ -f "$APPS_FILE" ]; then wapps="$(cat "$APPS_FILE")"
  else
    head2 "Which apps for this work machine?"
    note "design: figma  cleanshot  pika  imageoptim"
    note "dev:    vscode  orbstack  tableplus  proxyman  bruno"
    note "also:   adobe          (space-separated names, or 'all' / 'none')"
    wapps="${WORK_APPS:-$(ask 'apps:')}"
    [ "$wapps" = "all" ]  && wapps="figma cleanshot pika imageoptim vscode orbstack tableplus proxyman bruno adobe"
    [ "$wapps" = "none" ] && wapps=""
    echo "$wapps" > "$APPS_FILE"
  fi
  for app in $wapps; do case "$app" in
    figma)      cask_install figma ;;
    cleanshot)  cask_install cleanshot ;;
    pika)       cask_install pika ;;
    imageoptim) cask_install imageoptim ;;
    vscode)     cask_install visual-studio-code ;;
    orbstack)   cask_install orbstack ;;
    tableplus)  cask_install tableplus ;;
    proxyman)   cask_install proxyman ;;
    bruno)      cask_install bruno ;;
    adobe)      cask_install adobe-creative-cloud ;;
    *) note "unknown app: $app" ;;
  esac; done
fi

# Adobe Creative Cloud is large — opt in (desktop/laptop; work handles it above).
case "$PROFILE" in
  desktop|laptop)
    if ! brew list --cask adobe-creative-cloud >/dev/null 2>&1; then
      head2 "Install Adobe Creative Cloud? (large download)"
      if ask_yn "install Adobe CC" n; then cask_install adobe-creative-cloud; fi
    fi ;;
esac

# Work comms apps (asked once, remembered).
if [ "$PROFILE" = "work" ]; then
  COMMS_FILE="$HOME/.dotfiles-work-comms"
  if [ -f "$COMMS_FILE" ]; then comms="$(cat "$COMMS_FILE")"
  else
    head2 "Which comms apps for the work machine?"
    note "options: slack zoom teams telegram  (space-separated, or 'all' / 'none')"
    comms="${WORK_COMMS:-$(ask 'apps:')}"
    [ "$comms" = "all" ]  && comms="slack zoom teams telegram"
    [ "$comms" = "none" ] && comms=""
    echo "$comms" > "$COMMS_FILE"
  fi
  for app in $comms; do case "$app" in
    slack) cask_install slack ;; zoom) cask_install zoom ;;
    teams) cask_install microsoft-teams ;; telegram) cask_install telegram ;;
    *) note "unknown comms app: $app" ;;
  esac; done
fi

# --- First-run machine setup (optional, remembered) -------------------------
machine_setup() {
  hr; printf '   %sMachine setup%s %s— optional, answer N to skip any%s\n' "$BOLD" "$RESET" "$MUTED" "$RESET"

  # Editor
  head2 "Default editor?"
  note "1 VS Code   2 Cursor   3 Zed   4 nvim   5 vim"
  case "$(ask 'editor [1-5]:')" in
    1) ED="code -w" ;; 2) ED="cursor -w" ;; 3) ED="zed -w" ;; 4) ED="nvim" ;; 5) ED="vim" ;; *) ED="" ;;
  esac
  if [ -n "$ED" ]; then
    touch "$HOME/.zshrc.local"
    grep -v '^export EDITOR=\|^export GIT_EDITOR=' "$HOME/.zshrc.local" > "$HOME/.zshrc.local.tmp" 2>/dev/null || true
    mv "$HOME/.zshrc.local.tmp" "$HOME/.zshrc.local" 2>/dev/null || true
    printf 'export EDITOR="%s"\nexport GIT_EDITOR="%s"\n' "$ED" "$ED" >> "$HOME/.zshrc.local"
    ok "editor: $ED"
  fi

  # 1Password SSH agent
  ONEP=0
  head2 "Use 1Password as your SSH agent?"
  note "keys served from your vault, Touch ID per use (enable it in the 1Password app first)"
  if ask_yn "enable 1Password SSH agent" n; then
    ONEP=1
    # ssh expands ~ in IdentityAgent itself; the literal tilde is intentional.
    # shellcheck disable=SC2088
    local sock='~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock'
    if ! grep -q "agent.sock" "$HOME/.ssh/config.local" 2>/dev/null; then
      printf '\nHost *\n    IdentityAgent "%s"\n' "$sock" >> "$HOME/.ssh/config.local"
    fi
    ok "1Password SSH agent enabled (via ~/.ssh/config.local)"
  fi

  # GitHub CLI auth
  if command -v gh >/dev/null; then
    head2 "Authenticate the GitHub CLI now?"
    note "also sets up git credentials for HTTPS pushes"
    if ask_yn "run gh auth login" n; then gh auth login || note "gh auth skipped/failed"; fi
  fi

  # SSH key generation
  if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    head2 "No SSH key found — generate an ed25519 key?"
    [ "$ONEP" = 1 ] && note "(you chose 1Password; you may prefer to create the key in 1Password instead)"
    if ask_yn "generate ~/.ssh/id_ed25519" n; then
      ssh-keygen -t ed25519 -C "${WORK_EMAIL:-mike@innersparkmedia.com}" -f "$HOME/.ssh/id_ed25519" -N "" || true
      ok "key generated"
      if command -v gh >/dev/null && ask_yn "add it to GitHub via gh" n; then
        gh ssh-key add "$HOME/.ssh/id_ed25519.pub" || note "could not add key (is gh authed?)"
      fi
    fi
  fi

  # SSH commit signing
  head2 "Sign git commits with your SSH key? (Verified badge on GitHub)"
  if ask_yn "enable SSH commit signing" n; then
    local key=""
    [ -f "$HOME/.ssh/id_ed25519.pub" ] && key="$HOME/.ssh/id_ed25519.pub"
    {
      echo "[gpg]"; echo "    format = ssh"
      echo "[commit]"; echo "    gpgsign = true"
      [ -n "$key" ] && { echo "[user]"; echo "    signingkey = $key"; }
      if [ "$ONEP" = 1 ]; then
        echo '[gpg "ssh"]'
        echo '    program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"'
      fi
    } >> "$HOME/.gitconfig.local"
    ok "commit signing configured in ~/.gitconfig.local"
    [ -z "$key" ] && note "no ~/.ssh/id_ed25519.pub yet — set user.signingkey in ~/.gitconfig.local"
  fi

  # Node LTS
  if command -v fnm >/dev/null; then
    head2 "Install the latest Node LTS now?"
    if ask_yn "fnm install --lts" n; then
      eval "$(fnm env)" 2>/dev/null || true
      fnm install --lts && fnm default lts-latest 2>/dev/null || note "node install skipped/failed"
    fi
  fi

  # Computer name
  head2 "Set this machine's name?"
  name="$(ask 'computer name (blank to skip):')"
  if [ -n "$name" ]; then
    local lhn; lhn="$(echo "$name" | tr ' ' '-' | tr -cd '[:alnum:]-')"
    sudo scutil --set ComputerName "$name" || true
    sudo scutil --set HostName "$lhn" || true
    sudo scutil --set LocalHostName "$lhn" || true
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$lhn" || true
    ok "computer name: $name"
  fi

  # iTerm2 dynamic profile (font + theme), non-destructive
  head2 "Add a Spark iTerm2 profile (JetBrains Mono Nerd Font + theme)?"
  note "creates a new 'Spark' profile you can select; doesn't touch your current one"
  if ask_yn "add iTerm2 profile" y; then
    local dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    mkdir -p "$dir"
    cat > "$dir/spark.json" <<'JSON'
{ "Profiles": [ {
  "Name": "Spark",
  "Guid": "spark-dotfiles-profile",
  "Normal Font": "JetBrainsMonoNFM-Regular 13",
  "Non Ascii Font": "JetBrainsMonoNFM-Regular 13",
  "Use Non-ASCII Font": false,
  "Cursor Type": 2,
  "Background Color": { "Red Component": 0.117, "Green Component": 0.117, "Blue Component": 0.180 },
  "Foreground Color": { "Red Component": 0.803, "Green Component": 0.839, "Blue Component": 0.956 },
  "Cursor Color": { "Red Component": 0.537, "Green Component": 0.705, "Blue Component": 0.980 }
} ] }
JSON
    ok "iTerm2 'Spark' profile added (select it in iTerm2 > Settings > Profiles)"
    note "if glyphs look off, the font name may differ — check Nerd Font's exact name"
  fi

  # macOS defaults
  head2 "Apply macOS system defaults now? (Finder, Dock, input)"
  note "see macos/defaults.sh — only keys that still work, nothing dangerous"
  ask_yn "run macos/defaults.sh" n && bash "$DOTFILES/macos/defaults.sh" || true

  touch "$SETUP_MARKER"
}

if [ ! -f "$SETUP_MARKER" ] || [ "$RECONFIGURE" = 1 ]; then
  machine_setup
else
  note "machine setup already done — re-run with --reconfigure to redo it"
fi

hr
ok "Done. Profile '$BOLD$PROFILE$RESET'. Open a new terminal (or run: exec zsh)."
