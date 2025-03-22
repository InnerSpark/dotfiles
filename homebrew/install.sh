# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Install xcode command line tools
xcode-select --install

# Check for Homebrew,
# Install if we don't have it
if test ! $(which brew); then
  echo "Installing homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/mike.binder/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Update homebrew recipes
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Install GNU core utilities (those that come with OS X are outdated)
brew install coreutils

# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
brew install findutils

# Install Bash 4
brew install bash

# Install more recent versions of some OS X tools
binaries=(
  ack
  boost
  hub
  capnp
  cowsay
  elinks
  flac
  git
  gibo
  graphicsmagick
  hg
  lame
  lua
  luajit
  mackup
  mercurial
  multimarkdown
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
  latex2html
  ffmpeg
  cmus
  )

echo "installing binaries..."
brew install ${binaries[@]}

# Install Brew Cask for Mac Apps

brew install homebrew/cask
brew tap homebrew/cask

# Apps
apps=(
  adobe-creative-cloud
  appzapper
  arq
  avocode
  bartender
  brave-browser
  caffeine
  carbon-copy-cloner
  dropbox
  dropzone
  easyfind
  ember
  evernote
  fantastical
  firefox
  fluid
  forklift
  geekbench
  google-chrome
  handbrake
  hazel
  imgoptim
  iterm2-nightly
  line
  macvim
  marked
  mou
  spectacle
  path-finder
  parallels
  pdfsam-basic
  photoninja
  proctools
  sketch
  slack
  skype
  spotify
  todoist
  transmission-cli
  vlc
  1password
  qlmarkdown
  quicklook-json
  )

# Install apps to /Applications
# Default is: /Users/$user/Applications
echo "installing apps..."
brew install --cask --appdir="/Applications" ${apps[@]}

# install font set up
brew tap homebrew/cask-fonts

# fonts
fonts=(
	font-anonymous-pro \
	font-dejavu-sans-mono-for-powerline \
	font-droid-sans \
	font-droid-sans-mono font-droid-sans-mono-for-powerline \
	font-meslo-lg font-input \
	font-inconsolata font-inconsolata-for-powerline \
	font-liberation-mono font-liberation-mono-for-powerline \
	font-liberation-sans \
	font-meslo-lg \
	font-nixie-one \
	font-office-code-pro \
	font-pt-mono \
	font-roboto \
	font-source-code-pro font-source-code-pro-for-powerline \
	font-source-sans-pro \
	font-ubuntu font-ubuntu-mono-powerline
)

# install fonts
echo "installing fonts..."
brew install --cask ${fonts[@]}

# brew cask quicklook
echo_warn "Installing QuickLook Plugins..."
brew install --cask \
	qlcolorcode qlmarkdown qlprettypatch qlstephen \
	qlimagesize \
	quicklook-csv quicklook-json epubquicklook \
	animated-gif-quicklook

# Install vim 
brew install macvim

# Install Figma
brew install --cask figma

# Change path so Homebrew packages get priority
$PATH=$(brew --prefix coreutils)/libexec/gnubin:$PATH
