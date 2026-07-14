#!/usr/bin/env bash
# Server bootstrap for fresh Debian/Ubuntu boxes.
#   - installs a baseline package set + zsh/Starship shell
#   - symlinks the shared shell config for a target user
#   - optional hardening: sudo user, SSH lockdown, ufw, fail2ban, auto-updates
#
# Usage:
#   sudo ./server/bootstrap.sh [--user NAME] [--no-harden] [--yes]
#
# Safety: nothing that can lock you out happens without a confirmation and a
# pre-check. Password-auth is only disabled when a working authorized_keys is
# present, and ufw always allows the detected SSH port before it is enabled.

set -euo pipefail

# --- Re-exec as root --------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
  echo "Elevating with sudo..."
  exec sudo -E bash "$0" "$@"
fi

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- Args -------------------------------------------------------------------
TARGET_USER="${SUDO_USER:-}"
HARDEN=1
ASSUME_YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --user) TARGET_USER="$2"; shift 2 ;;
    --no-harden) HARDEN=0; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done
[ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ] && TARGET_USER=""

log()  { echo -e "\n==> $1"; }
warn() { echo "!!  $1" >&2; }

# Confirm reads from the terminal even when the script is piped in.
confirm() {
  [ "$ASSUME_YES" = "1" ] && return 0
  local reply
  if [ -r /dev/tty ]; then
    read -rp "$1 [y/N]: " reply </dev/tty || reply=""
  else
    return 1
  fi
  [[ "$reply" =~ ^[Yy]$ ]]
}

if ! command -v apt-get >/dev/null; then
  warn "This bootstrap targets Debian/Ubuntu (apt). Aborting."
  exit 1
fi
export DEBIAN_FRONTEND=noninteractive

# --- 1. Packages ------------------------------------------------------------
log "Updating and upgrading system packages"
apt-get update -qq
apt-get upgrade -y -qq

log "Installing baseline packages"
while read -r pkg; do
  pkg="${pkg%%#*}"; pkg="$(echo "$pkg" | xargs)"   # strip comments/whitespace
  [ -z "$pkg" ] && continue
  if apt-get install -y -qq --no-install-recommends "$pkg" 2>/dev/null; then
    echo "  installed $pkg"
  else
    warn "skipped $pkg (not available)"
  fi
done < "$DOTFILES/server/packages.txt"

# --- 2. Starship ------------------------------------------------------------
if ! command -v starship >/dev/null; then
  log "Installing Starship"
  curl -sS https://starship.rs/install.sh | sh -s -- -y || warn "Starship install failed"
fi

# --- 3. Shell config for the target user ------------------------------------
setup_shell_for() {
  local user="$1" home
  home="$(getent passwd "$user" | cut -d: -f6)"
  [ -z "$home" ] && { warn "no home for $user"; return; }
  log "Linking shell config for $user ($home)"
  install -d -o "$user" -g "$user" "$home/.config"
  ln -sfn "$DOTFILES/zsh/zshrc"            "$home/.zshrc"
  ln -sfn "$DOTFILES/zsh/aliases.zsh"      "$home/.aliases.zsh"
  ln -sfn "$DOTFILES/config/starship.toml" "$home/.config/starship.toml"
  ln -sfn "$DOTFILES/server/gitconfig"     "$home/.gitconfig"
  ln -sfn "$DOTFILES/git/gitignore_global" "$home/.gitignore_global"
  chown -h "$user:$user" "$home/.zshrc" "$home/.aliases.zsh" \
    "$home/.config/starship.toml" "$home/.gitconfig" "$home/.gitignore_global" 2>/dev/null || true
  if command -v zsh >/dev/null; then
    chsh -s "$(command -v zsh)" "$user" && echo "  default shell -> zsh"
  fi
}

# --- 4. Hardening -----------------------------------------------------------
if [ "$HARDEN" = "1" ]; then
  # 4a. Sudo user
  if [ -z "$TARGET_USER" ]; then
    if confirm "Create a non-root sudo user?"; then
      read -rp "Username: " TARGET_USER </dev/tty
      if ! id "$TARGET_USER" >/dev/null 2>&1; then
        adduser --disabled-password --gecos "" "$TARGET_USER"
      fi
      usermod -aG sudo "$TARGET_USER"
      # carry root's key over so the new user has SSH access
      if [ -f /root/.ssh/authorized_keys ]; then
        install -d -m 700 -o "$TARGET_USER" -g "$TARGET_USER" "/home/$TARGET_USER/.ssh"
        install -m 600 -o "$TARGET_USER" -g "$TARGET_USER" \
          /root/.ssh/authorized_keys "/home/$TARGET_USER/.ssh/authorized_keys"
        echo "  copied root's authorized_keys to $TARGET_USER"
      fi
    fi
  fi

  # 4b. SSH hardening via drop-in
  SSH_PORT="$(awk '/^[Pp]ort /{print $2; exit}' /etc/ssh/sshd_config)"; SSH_PORT="${SSH_PORT:-22}"
  keys_present=0
  [ -s "/home/$TARGET_USER/.ssh/authorized_keys" ] && keys_present=1
  [ -s /root/.ssh/authorized_keys ] && keys_present=1

  if ! grep -qiE '^\s*Include\s+/etc/ssh/sshd_config\.d' /etc/ssh/sshd_config; then
    warn "sshd_config has no Include for sshd_config.d; the drop-in may be ignored. Skipping SSH changes."
  else
    DROPIN=/etc/ssh/sshd_config.d/99-mike-hardening.conf
    log "Configuring SSH hardening (port $SSH_PORT detected)"
    { echo "# Managed by dotfiles server bootstrap"
      echo "PubkeyAuthentication yes"
      echo "PermitRootLogin prohibit-password"   # root key still works; no root password
      echo "X11Forwarding no"
    } > "$DROPIN"
    if [ "$keys_present" = "1" ] && confirm "Disable SSH password auth (key-only)? Confirm your key login works first"; then
      echo "PasswordAuthentication no" >> "$DROPIN"
      echo "  password auth disabled"
    else
      echo "  leaving password auth as-is"
    fi
    if sshd -t 2>/dev/null; then
      systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
      echo "  sshd reloaded"
    else
      warn "sshd -t failed; removing drop-in to avoid breaking SSH"
      rm -f "$DROPIN"
    fi
  fi

  # 4c. Firewall (allow SSH first, then enable)
  if command -v ufw >/dev/null; then
    log "Enabling ufw (allowing SSH on $SSH_PORT)"
    ufw allow "$SSH_PORT"/tcp >/dev/null || true
    ufw --force enable >/dev/null || true
    ufw status | sed 's/^/  /'
  fi

  # 4d. fail2ban
  if command -v fail2ban-server >/dev/null; then
    log "Enabling fail2ban"
    systemctl enable --now fail2ban >/dev/null 2>&1 || true
  fi

  # 4e. Automatic security updates
  if dpkg -s unattended-upgrades >/dev/null 2>&1; then
    log "Enabling automatic security updates"
    cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
  fi
fi

# --- Shell setup (after any user creation) ----------------------------------
if [ -n "$TARGET_USER" ] && id "$TARGET_USER" >/dev/null 2>&1; then
  setup_shell_for "$TARGET_USER"
else
  setup_shell_for root
fi

log "Server bootstrap complete."
echo "  - Log out and back in for the zsh shell to take effect."
[ -n "$TARGET_USER" ] && echo "  - If you created $TARGET_USER, test 'ssh $TARGET_USER@<host>' in a NEW terminal before closing this one."
