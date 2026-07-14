#!/usr/bin/env bash
# macOS defaults — the keepers from the old "OSX for Hackers" script,
# limited to keys that still work on current macOS (verified July 2026).
#
# Dropped on purpose:
#   - Gatekeeper disable, LSQuarantine off, disk image verification off
#     (security downgrades; modern macOS fights you on them anyway)
#   - Safari/Mail/Messages defaults (sandboxed since Mojave; writes from
#     the terminal fail without Full Disk Access)
#   - pmset sleep 0, sudden motion sensor, standbydelay, tmutil disablelocal,
#     HiDPI, subpixel smoothing, Bluetooth bitpool (removed or ignored keys)

set -euo pipefail

echo "Applying macOS defaults..."

# --- General UI/UX -----------------------------------------------------------
# Expand save and print panels by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Quit the printer app once print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable smart quotes and smart dashes (annoying when typing code)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# --- Input -------------------------------------------------------------------
# Full keyboard access for all controls (Tab through dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Trackpad and mouse speed
defaults write -g com.apple.trackpad.scaling -float 2
defaults write -g com.apple.mouse.scaling -float 2.5

# --- Security ---------------------------------------------------------------
# Require password immediately after sleep or screen saver
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# --- Finder --------------------------------------------------------------------
# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar and full POSIX path in window title
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Column view by default
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# No warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# No .DS_Store litter on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --- Dock -----------------------------------------------------------------------
# Left side, small tiles, show only running apps, mark hidden apps
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock static-only -bool true
defaults write com.apple.dock showhidden -bool true

# Speed up Mission Control animations, group windows by app
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock expose-group-apps -bool true

# --- Apply ------------------------------------------------------------------------
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
echo "Done. Some changes need a logout/restart to take effect."
