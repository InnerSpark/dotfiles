# Dotfiles

Personal setup for macOS (Apple Silicon) and Debian/Ubuntu servers. Rebuilt
July 2026 from the 2015-era bash-it version: zsh instead of bash, Starship
instead of powerline themes, a layered Brewfile instead of package lists,
per-machine profiles, and a small installer instead of DFM.

## Install (Mac)

```sh
git clone https://github.com/InnerSpark/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
./install.sh            # prompts for a profile the first time
```

The installer symlinks configs into `$HOME` (backing up anything it replaces
into `~/.dotfiles-backup-<timestamp>/`), sets up ssh, and installs the Homebrew
packages for the chosen profile. It is safe to re-run. The profile is saved to
`~/.dotfiles-profile`, so later `./install.sh` runs repeat it without asking.

Running on a machine that already has SSH hosts is safe: the installer migrates
your existing `~/.ssh/config` into `~/.ssh/config.local` (via the Include)
rather than overwriting it, and the 1Password agent line ships commented out so
your on-disk keys keep working until you turn it on.

## Profiles

Each machine picks one profile. Apps are layered: a common base plus the
fragments that profile needs.

| Profile | Machines | Layers |
|---|---|---|
| `desktop` | M4 Studio, M1 Studio | common + design + dev + personal + desktop |
| `laptop`  | personal MacBook Pro, Mac Mini | common + design + dev + personal |
| `work`    | work MacBook Pro | common + apps you select (prompts for git email, design/dev apps, comms) |
| `server`  | Debian/Ubuntu boxes | runs `server/bootstrap.sh` (see Servers) |

Force a profile explicitly: `./install.sh work`. Preview without changing
anything: `./install.sh desktop --dry-run`.

## First-run setup

After installing packages, the installer runs a one-time set of optional
questions (skip any with `N`; re-run them later with `./install.sh --reconfigure`):

- Default editor (VS Code / Cursor / Zed / nvim / vim) → written to `~/.zshrc.local`
- Enable the 1Password SSH agent → adds the `IdentityAgent` line to `~/.ssh/config.local`
- `gh auth login` (also fixes HTTPS push credentials)
- Generate an ed25519 SSH key if none exists, optionally add it to GitHub
- SSH commit signing → written to `~/.gitconfig.local`
- Install the latest Node LTS via `fnm`
- Set the computer / host name
- Add a "Spark" iTerm2 profile (JetBrains Mono Nerd Font + theme)
- Apply `macos/defaults.sh`

Adobe Creative Cloud is a separate yes/no prompt during install (large download).

## Applications installed

Each header lists which profiles include that layer. Nothing is removed from a
machine; `brew bundle` only adds.

### Common — every Mac (desktop, laptop, work)

CLI: `starship`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `git`, `gh`,
`fzf`, `zoxide`, `eza`, `bat`, `ripgrep`, `fd`, `jq`, `tree`, `wget`,
`shellcheck`, `tlrc`, `fnm`, `ffmpeg`, `imagemagick`.

Apps: iTerm2, Raycast, Ice, 1Password, Google Chrome, Firefox, Notion,
Granola, RustDesk, Claude (desktop), Claude Code.

Font: JetBrains Mono Nerd Font.

### Design — desktop, laptop (work: pick individually)

Figma, Adobe Creative Cloud, CleanShot X, Pika (color picker + WCAG contrast),
ImageOptim.

### Dev — desktop, laptop (work: pick individually)

VS Code, OrbStack (Docker runtime), TablePlus, Proxyman, Bruno.

### Personal — desktop, laptop (kept off the work machine)

Spotify, VLC, HandBrake, Dropbox, Google Drive, Slack, Zoom, Microsoft Teams,
Telegram, Tailscale (mesh VPN; personal machines and servers, not work).

### Work profile — you pick

Unlike desktop/laptop, the `work` profile installs nothing beyond the common
layer automatically. It prompts for:

- which design/dev apps to install (`figma cleanshot pika imageoptim vscode
  orbstack tableplus proxyman bruno adobe`, or `all` / `none`) → remembered in
  `~/.dotfiles-work-apps`
- which comms apps (`slack zoom teams telegram`, or `all` / `none`) →
  `~/.dotfiles-work-comms`

Skip either prompt on re-runs by leaving the saved file, or preset them with
`WORK_APPS="figma vscode" WORK_COMMS="slack" ./install.sh work`.

### Desktop-only — desktop

Parallels, Carbon Copy Cloner.

### Server (apt) — server profile

`zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `git`, `curl`, `wget`,
`ca-certificates`, `gnupg`, `tmux`, `htop`, `ncdu`, `tree`, `unzip`, `jq`,
`ripgrep`, `fd-find`, `bat`, `fzf`, `build-essential`, `ufw`, `fail2ban`,
`unattended-upgrades`, plus Starship. See `server/packages.txt`.

## Servers

On a fresh Linux box, clone the repo and run the bootstrap (it re-elevates with
sudo itself):

```sh
git clone https://github.com/InnerSpark/dotfiles.git ~/dotfiles
~/dotfiles/server/bootstrap.sh              # or: ./install.sh server
```

It installs the baseline packages, sets up zsh + Starship to match the Macs,
symlinks the shared shell config, and walks through optional hardening: a
non-root sudo user, SSH lockdown (key-only, no root password), ufw, fail2ban,
and automatic security updates.

Hardening is safe by design. SSH hardening is skipped entirely if the box is
already hardened (it never overrides an SSH config you set up yourself), and is
opt-in otherwise. Password auth is only disabled when a working
`authorized_keys` is present and you confirm, ufw always allows the detected
SSH port before enabling, and every sshd change is validated with `sshd -t`
(and rolled back if it fails). It also offers to install Tailscale. Flags:
`--no-harden`, `--user NAME`, `--yes`.

## Layout

| Path | What it is |
|---|---|
| `install.sh` | Profile-aware Mac installer. |
| `Brewfile` | Common packages, every Mac. |
| `brew/*.Brewfile` | design, dev, personal, desktop app layers. |
| `zsh/` | Shell config (cross-platform: macOS + Linux). |
| `config/starship.toml` | Prompt. |
| `git/gitconfig` | Identity, defaults, aliases; work identity for `~/work/` repos. |
| `git/gitconfig.work.example` | Template; the real one is generated by install. |
| `ssh/config` | Publish-safe: defaults + GitHub + (optional) 1Password agent. |
| `ssh/config.local.example` | Template for real hosts (real file at `~/.ssh/config.local`). |
| `server/bootstrap.sh` | Fresh-server provisioning + hardening. |
| `server/packages.txt` | apt package list. |
| `server/gitconfig` | Lean git config for servers (no macOS keychain). |
| `macos/defaults.sh` | Finder/Dock/input preferences. |

## Per-machine and secret config

Anything machine-specific or private stays out of the repo and is applied if
present:

- `~/.zshrc.local` — shell tweaks for one machine
- `~/.gitconfig.local` — git identity/overrides for one machine
- `~/.gitconfig.work` — work email (generated by the `work` profile)
- `~/.ssh/config.local` — real SSH hosts (IPs, ports, users)

## Notes

The prompt needs a Nerd Font; the Brewfile installs JetBrains Mono Nerd Font.
`zoxide` replaces fasd (`z <partial>`), `fnm` replaces nvm, `eza` backs the
`ls` aliases, and OrbStack provides the `docker` CLI. Claude Code and the
Claude desktop app are in the common layer.

## Disclaimer

These scripts modify system settings, install software, run with `sudo`, and
(on servers) change SSH and firewall configuration. Read them before running
on a machine you care about. Provided as-is, with no warranty; use at your own
risk.

## Credits

`macos/defaults.sh` descends from the "OSX for Hackers" gist and the
mathiasbynens/dotfiles lineage, trimmed to keys that still work on current
macOS.

## License

MIT. See [LICENSE](LICENSE).
