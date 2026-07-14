# Brewfile — COMMON layer. Installed on every Mac regardless of profile.
# Profile-specific apps live in brew/*.Brewfile and are layered on top by
# install.sh. Sync a machine with: ./install.sh <profile>

# --- Shell + prompt ---------------------------------------------------------
brew "starship"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# --- CLI essentials ---------------------------------------------------------
brew "git"
brew "gh"
brew "fzf"
brew "zoxide"
brew "eza"
brew "bat"
brew "ripgrep"
brew "fd"
brew "jq"
brew "tree"
brew "wget"
brew "shellcheck"
brew "tlrc"
brew "fnm"

# --- Media / design CLI -----------------------------------------------------
brew "ffmpeg"
brew "imagemagick"

# --- Claude (daily driver, every machine) -----------------------------------
cask "claude"
cask "claude-code"

# --- Core apps (every Mac) --------------------------------------------------
cask "iterm2"
cask "raycast"                        # launcher; also does clipboard + windows
cask "jordanbaird-ice"                # menu bar manager (Ice)
cask "1password"
cask "google-chrome"
cask "firefox"
cask "slack"
cask "notion"                         # notes / docs
cask "granola"                        # AI meeting notes

# --- Fonts ------------------------------------------------------------------
cask "font-jetbrains-mono-nerd-font"  # glyphs for the Starship prompt
