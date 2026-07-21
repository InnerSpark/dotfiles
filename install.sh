#!/usr/bin/env bash
# Spark dotfiles installer — profile-aware, everything opt-in.
#
# Usage:
#   ./install.sh [profile] [--yes] [--dry-run]
#
# Profiles:
#   desktop  Studios / always-on Macs
#   laptop   personal laptop, Mac Mini
#   work     work laptop
#   server   Linux / headless (delegates to server/bootstrap.sh)
#
# Every step asks before it runs (link config, install apps, machine setup,
# macOS defaults), so you can skip any part on any machine.
#
# Flags:
#   --yes       run every step without asking (unattended full install)
#   --dry-run   show the plan and change nothing

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
OS="$(uname)"
PROFILE_FILE="$HOME/.dotfiles-profile"

# --- Args -------------------------------------------------------------------
PROFILE=""; DRY_RUN=0; YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y) YES=1 ;;
    --dry-run) DRY_RUN=1 ;;
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

ask_yn() {  # $1 prompt, $2 default(y/n)
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
# Section gate: honored unless --yes (which auto-approves every step).
gate() { [ "$YES" = 1 ] && return 0; ask_yn "$1" "${2:-y}"; }

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
  printf '   %s1%s desktop  %sStudios — everything%s\n'             "$SKY" "$RESET" "$MUTED" "$RESET"
  printf '   %s2%s laptop   %spersonal MacBook, Mac Mini%s\n'       "$SKY" "$RESET" "$MUTED" "$RESET"
  printf '   %s3%s work     %swork MacBook%s\n'                     "$SKY" "$RESET" "$MUTED" "$RESET"
  printf '   %s4%s server   %sLinux — bootstrap + hardening%s\n'    "$SKY" "$RESET" "$MUTED" "$RESET"
  case "$(ask 'Profile [1-4]:')" in
    1) PROFILE=desktop ;; 2) PROFILE=laptop ;; 3) PROFILE=work ;; 4) PROFILE=server ;;
    *) echo "Unknown choice."; exit 1 ;;
  esac
fi
case "$PROFILE" in desktop|laptop|work|server) ;; *) echo "Unknown profile: $PROFILE"; exit 1 ;; esac

# --- Dry run ----------------------------------------------------------------
if [ "$DRY_RUN" = 1 ]; then
  hr; note "DRY RUN — profile: $PROFILE. Nothing changes. Each step below is asked first."
  note "1. link shell/git/ssh config"
  case "$PROFILE" in
    server)  note "2. run server/bootstrap.sh (packages + hardening)" ;;
    work)    note "2. install: common + apps you pick + comms you pick" ;;
    laptop)  note "2. install: common + layers you pick (design dev personal)" ;;
    desktop) note "2. install: common + layers you pick (design dev personal desktop)" ;;
  esac
  note "3. machine setup (editor, 1Password, gh, SSH key, signing, Node, name, iTerm)"
  note "4. apply macOS defaults"
  exit 0
fi

echo "$PROFILE" > "$PROFILE_FILE"
printf '\n'; ok "profile: $BOLD$PROFILE$RESET"
if [ "$YES" = 1 ]; then note "--yes: running every step without asking"
else note "each step asks first — answer N to skip any"; fi

# --- Server profile delegates to the Linux bootstrap ------------------------
if [ "$PROFILE" = "server" ]; then exec bash "$DOTFILES/server/bootstrap.sh"; fi

# --- Helpers ----------------------------------------------------------------
link() {
  local src="$DOTFILES/$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then mkdir -p "$BACKUP"; mv "$dest" "$BACKUP/"; fi
  ln -sfn "$src" "$dest"
}
bundle() {
  printf '\n%s==>%s brew bundle: %s\n' "$SKY" "$RESET" "$1"
  brew bundle --file="$DOTFILES/$1" || note "some entries in $1 need attention; continuing"
}
cask_install() { brew install --cask "$1" || note "$1 needs attention; continuing"; }

# ============================================================================
# 1. Shell / git / ssh config
# ============================================================================
if gate "Link shell, git, and SSH config?" y; then
  link zsh/zshrc            "$HOME/.zshrc"
  link zsh/zprofile         "$HOME/.zprofile"
  link zsh/aliases.zsh      "$HOME/.aliases.zsh"
  link config/starship.toml "$HOME/.config/starship.toml"
  link git/gitconfig        "$HOME/.gitconfig"
  link git/gitignore_global "$HOME/.gitignore_global"
  ok "shell + git config linked"

  if [ "$PROFILE" = "work" ]; then
    WORK_GIT="$HOME/.gitconfig.work"
    if [ ! -f "$WORK_GIT" ] || grep -q "CHANGE-ME" "$WORK_GIT" 2>/dev/null; then
      head2 "Work git email (for repos under ~/work/)"
      email="${WORK_EMAIL:-$(ask 'email:')}"
      if [ -n "$email" ]; then
        printf '# Work identity — repos under ~/work/.\n[user]\n\temail = %s\n' "$email" > "$WORK_GIT"
        chmod 600 "$WORK_GIT"; ok "work identity: $email"
      fi
    fi
  fi

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
fi

# ============================================================================
# 2. Homebrew packages / apps
# ============================================================================
if [ "$OS" = "Darwin" ] && gate "Install Homebrew packages and apps?" y; then
  # Load Homebrew if installed but not on PATH yet.
  if ! command -v brew >/dev/null; then
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [ -x "$b" ]; then eval "$("$b" shellenv)"; break; fi
    done
  fi
  # Install Homebrew only if genuinely absent.
  if ! command -v brew >/dev/null; then
    if gate "Homebrew isn't installed — install it now?" y; then
      note "you may be asked for your password (Homebrew needs sudo)"
      NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
        || note "Homebrew install failed (network?)"
      if   [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [ -x /usr/local/bin/brew   ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
    fi
  fi

  if ! command -v brew >/dev/null; then
    note "Homebrew not available; skipping app install"
  else
    bundle Brewfile   # common baseline

    if [ "$PROFILE" = "work" ]; then
      # Work: pick individual apps (remembered), then comms.
      APPS_FILE="$HOME/.dotfiles-work-apps"
      if [ -f "$APPS_FILE" ] && [ "$YES" = 1 ]; then wapps="$(cat "$APPS_FILE")"
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
        figma) cask_install figma ;; cleanshot) cask_install cleanshot ;;
        pika) cask_install pika ;; imageoptim) cask_install imageoptim ;;
        vscode) cask_install visual-studio-code ;; orbstack) cask_install orbstack ;;
        tableplus) cask_install tableplus ;; proxyman) cask_install proxyman ;;
        bruno) cask_install bruno ;; adobe) cask_install adobe-creative-cloud ;;
        *) note "unknown app: $app" ;;
      esac; done

      COMMS_FILE="$HOME/.dotfiles-work-comms"
      if [ -f "$COMMS_FILE" ] && [ "$YES" = 1 ]; then comms="$(cat "$COMMS_FILE")"
      else
        head2 "Which comms apps for the work machine?"
        note "slack zoom teams telegram  (space-separated, or 'all' / 'none')"
        comms="${WORK_COMMS:-$(ask 'comms:')}"
        [ "$comms" = "all" ]  && comms="slack zoom teams telegram"
        [ "$comms" = "none" ] && comms=""
        echo "$comms" > "$COMMS_FILE"
      fi
      for app in $comms; do case "$app" in
        slack) cask_install slack ;; zoom) cask_install zoom ;;
        teams) cask_install microsoft-teams ;; telegram) cask_install telegram ;;
        *) note "unknown comms app: $app" ;;
      esac; done

    else
      # desktop / laptop: choose which app layers to install.
      case "$PROFILE" in
        laptop)  avail="design dev personal" ;;
        desktop) avail="design dev personal desktop" ;;
      esac
      head2 "Which app layers?"
      note "$avail   (space-separated, or 'all' / 'none')"
      sel="${LAYERS:-$(ask 'layers [all]:')}"
      [ -z "$sel" ] && sel="all"
      [ "$sel" = "all" ]  && sel="$avail"
      [ "$sel" = "none" ] && sel=""
      for l in $sel; do case "$l" in
        design)   bundle brew/design.Brewfile ;;
        dev)      bundle brew/dev.Brewfile ;;
        personal) bundle brew/personal.Brewfile ;;
        desktop)  bundle brew/desktop.Brewfile ;;
        *) note "unknown layer: $l" ;;
      esac; done
      # Adobe CC is large — separate opt-in.
      if printf '%s ' $sel | grep -qw design && ! brew list --cask adobe-creative-cloud >/dev/null 2>&1; then
        if ask_yn "Install Adobe Creative Cloud? (large download)" n; then cask_install adobe-creative-cloud; fi
      fi
    fi
  fi
fi

# ============================================================================
# 3. Machine setup (editor, 1Password, keys, Node, name, iTerm)
# ============================================================================
machine_setup() {
  # Editor
  head2 "Default editor?"
  note "1 VS Code   2 Cursor   3 Zed   4 nvim   5 vim   (blank to skip)"
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
  note "enable it in the 1Password app first; keys served with Touch ID"
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

  # SSH key
  if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    head2 "No SSH key found — generate an ed25519 key?"
    [ "$ONEP" = 1 ] && note "(you chose 1Password; you may prefer to create the key there)"
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
  head2 "Set this machine's name? (blank to skip)"
  name="$(ask 'computer name:')"
  if [ -n "$name" ]; then
    local lhn; lhn="$(echo "$name" | tr ' ' '-' | tr -cd '[:alnum:]-')"
    sudo scutil --set ComputerName "$name" || true
    sudo scutil --set HostName "$lhn" || true
    sudo scutil --set LocalHostName "$lhn" || true
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$lhn" || true
    ok "computer name: $name"
  fi

  # iTerm2 dynamic profile
  head2 "Add a Spark iTerm2 profile (JetBrains Mono Nerd Font + theme)?"
  note "creates a new 'Spark' profile; doesn't touch your current one"
  if ask_yn "add iTerm2 profile" y; then
    local dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    mkdir -p "$dir"
    cat > "$dir/spark.json" <<'JSON'
{ "Profiles": [ {
  "Name": "Spark",
  "Guid": "spark-dotfiles-profile",
  "Normal Font": "JetBrainsMonoNFM-Regular 13",
  "Cursor Type": 2,
  "Background Color": { "Red Component": 0.117, "Green Component": 0.117, "Blue Component": 0.180 },
  "Foreground Color": { "Red Component": 0.803, "Green Component": 0.839, "Blue Component": 0.956 },
  "Cursor Color": { "Red Component": 0.537, "Green Component": 0.705, "Blue Component": 0.980 }
} ] }
JSON
    ok "iTerm2 'Spark' profile added (select it in iTerm2 > Settings > Profiles)"
  fi
}

if [ "$OS" = "Darwin" ] && gate "Run machine setup (editor, 1Password, keys, Node, name, iTerm)?" n; then
  machine_setup
fi

# ============================================================================
# 4. macOS system defaults
# ============================================================================
if [ "$OS" = "Darwin" ] && gate "Apply macOS system defaults (Finder, Dock, input)?" n; then
  bash "$DOTFILES/macos/defaults.sh"
fi

hr
ok "Done. Profile '$BOLD$PROFILE$RESET'. Open a new terminal (or run: exec zsh)."
