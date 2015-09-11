echo "This script will setup a lamp based server"

# Check for Homebrew,
# Install if we don't have it
if test ! $(which brew); then
  echo "Installing Dependancies"
  sudo apt-get install build-essential curl git m4 ruby texinfo libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev
  echo "Installing homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)"
fi

# Update homebrew recipes
brew update

# Upgrade any already-installed formulae.
brew upgrade --all

# Install GNU core utilities
brew install coreutils

# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
brew install findutils

# Install Bash 4
brew install bash

# Install more recent versions of some tools
brew tap homebrew/dupes
brew install homebrew/dupes/grep

binaries=(
  ack
  hub
  capnp
  cmus --with-ffmpeg
  cowsay
  elinks
  ffmpeg
  flac
  git
  gibo
  google-sparsehash
  graphicsmagick
  hg
  lame
  latex2html
  lua
  luajit
  mackup
  mercurial
  multimarkdown
  mysql
  ninja
  pandoc
  pandoc-citeproc
  par
  pdf2htmlex
  python
  ragel
  ranger
  reattach-to-user-namespace
  rename
  ruby
  the_silver_searcher
  task
  tree
  tmux
  trash
  wget
  xvid
  webkit2png
  )
  
echo "installing binaries..."
brew install ${binaries[@]}

echo "Installing Apache2"
brew install -v httpd22 --with-brewed-openssl