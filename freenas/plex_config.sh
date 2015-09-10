# This script sets up my freenas plex configuration with plex connect.

# Ask for the admin password upfront
sudo -v

# update pkgs
echo "Updating PortSnap..."
pkg upgrade
