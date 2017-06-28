#  Spark Dotfiles
___

There has been to many times where I have had to configure a new server or computer from scratch. We all know how long this takes and how painful it can be to try and remember every app, every configuration and every tool we need or use day in and day out on each one of our computers or servers. This repo is here to help with that and to configure each and every one of my environments so that way I can spend more time doing what I love *(UX Design)* and less time configuring and setting up.

##  Getting Started
The first step we need to do is figure out what we are setting up. Are we setting up a new MacOS install, a web server, a development environment *(ideally this would be the same as your web server)* or something else all together.

The first thing no mater what we are setting up is we need to get our Dotfiles installed from GitHub.

	git clone https://github.com/InnerSpark/dotfiles.git $HOME/.dotfiles

Next lets have DFM install the dotfiles.

	./.dotfiles/bin/dfm install

Ok so now we have our base setup. Wahoo!

##  MacOS Setup

If we are setting up a new computer *(MacOS)* then the first thing we are going to want to do is it up so that all the features we want and don't want configured on the base os are taken care of. This next script does just that for you.

	./.dotfile/macos/setup.sh

If you winder exactly what this script does, I would recommend opening it up and reading it. If you don't have the time for that, the best way i can describe it is that it runs allot of commands to change config setting in MacOS that may or may not be useful.

## HomeBrew

So I personaly use home brew to manage all my packages and applications. This next script will install the software that I use all the time, which allows me from having to go manualy download and install each one of them. In my opinion this thing is a life savor!

	./.dotfiles/homebrew/install.sh

### Install Packages
    brew install $(<~/.dotfiles/homebrew/packages.txt)

#### List of Packages to Install
* ack
* ant
* apparix
* archey
* asciidoc
* asciinema
* aspell
* atk
* autoconf
* automake
* bash-completion
* bash-git-prompt
* bdw-gc
* berkeley-db
* boost
* boost-python
* boot-clj
* boot2docker
* cabal-install
* cabextract
* cairo
* cask
* ccat
* cheat
* chicken
* chrome-cli
* clisp
* clojurescript
* cloog
* closure-compiler
* cmake
* codequery
* colordiff
* coreutils
* cowsay
* cscope
* ctags
* curl
* curlish
* czmq
* dateutils
* dcraw
* deisctl
* dnsmasq
* docbook
* docbook-xsl
* docker
* dos2unix
* doxygen
* drip
* duti
* ecj
* editorconfig
* elinks
* emacs
* exif
* exiftags
* exiftool
* expat
* faac
* faad2
* fasd
* ffmpeg
* fig
* figlet
* findutils
* fontconfig
* fontforge
* fortune
* fpp
* freetype
* fswatch
* fzf
* gawk
* gcc
* gd
* gdbm
* gdk-pixbuf
* geoip
* gettext
* ghc
* ghostscript
* giflib
* gifsicle
* gist
* git
* git-annex
* git-extras
* git-flow
* git-hooks
* git-lfs
* glib
* global
* gmp
* go
* gobject-introspection
* gpac
* graphicsmagick
* graphviz
* grep
* gsasl
* gtk+
* gts
* haproxy
* harfbuzz
* heroku-toolbelt
* hicolor-icon-theme
* highlight
* htmlcleaner
* httpie
* ical-buddy
* icu4c
* id3tool
* ilmbase
* imagemagick
* intltool
* irssi
* isl
* jasper
* jbig2dec
* jpeg
* jpeg-archive
* jpeg-turbo
* jpeginfo
* jpegoptim
* known_hosts
* lame
* ledger
* leiningen
* lesspipe
* libassuan
* libatomic_ops
* libcaca
* libcroco
* libdnet
* libevent
* libexif
* libffi
* libgcrypt
* libgpg-error
* libgphoto2
* libicns
* libiconv
* libidn
* libiscsi
* libksba
* liblqr
* libmpc
* libogg
* libpng
* libpng12
* libquvi
* librsvg
* libsigsegv
* libtasn1
* libtiff
* libtool
* libusb
* libusb-compat
* libvo-aacenc
* libvorbis
* libwebm
* libwmf
* libxml2
* libyaml
* lighttpd
* little-cms
* little-cms2
* llvm
* lua
* luajit
* lynx
* lzlib
* lzo
* macvim
* mackup
* mad
* makedepend
* maven
* md5sha1sum
* media-info
* mercurial
* mozjpeg
* mpfr
* mtr
* multimarkdown
* nasm
* neon
* neovim
* netcat
* netpbm
* nettle
* nmap
* npth
* nvm
* openconnect
* openexr
* openjpeg
* openssh
* openssl
* optipng
* p7zip
* packer-completion
* pandoc
* pango
* passpie
* pcre
* pigz
* pinentry
* pixman
* pkg-config
* plantuml
* plt-racket
* pmd
* pngcrush
* pngnq
* pngquant
* poco
* popt
* postgresql
* pstree
* pth
* purescript
* pyqt
* python
* qscintilla2
* qt
* quvi
* ranger
* rbenv
* readline
* reattach-to-user-namespace
* redis
* rethinkdb
* rsync
* ruby-build
* sane-backends
* sbcl
* scheme48
* scons
* sdl
* sdl_image
* shellcheck
* sip
* sl
* smartypants
* sqlite
* ssh-copy-id
* sslmate
* stow
* surfraw
* taglib
* texi2html
* the_silver_searcher
* tidy-html5
* tidyp
* tldr
* tmux
* tnef
* transmission
* trash
* tree
* ttfautohint
* tvnamer
* unison
* unrar
* urlview
* vcprompt
* w3m
* watchman
* webalizer
* webkit2png
* webp
* wget
* wrk
* x264
* xmlto
* xvid
* xz
* yasm
* zeromq
* zopfli

### Install Cask Packages
    brew cask install $(<~/.dotfiles/homebrew/cask_packages.txt)

#### List of Cask Packages to Install
* adobe-creative-cloud
* amazon-cloud-drive
* animated-gif-quicklook
* app-tamer
* appzapper
* atom
* bartender
* bettertouchtool
* betterzipql
* bittorrent-sync
* calibre
* cheatsheet
* controlplane
* dropbox
* dropzone
* ember
* epubquicklook
* expandrive
* firefox
* firefoxdeveloperedition
* flash
* font-anonymous-pro-for-powerline
* font-arial
* font-bebas-neue
* font-dejavu-sans-mono-for-powerline
* font-droid-sans-mono-for-powerline
* font-fira-mono-for-powerline
* font-fira-sans
* font-hasklig
* font-inconsolata
* font-inconsolata-dz-for-powerline
* font-inconsolata-for-powerline
* font-inconsolata-g-for-powerline
* font-liberation-mono-for-powerline
* font-meslo-lg-for-powerline
* font-open-iconic
* font-open-sans
* font-raleway
* font-sauce-code-powerline
* font-source-code-pro
* font-source-code-pro-for-powerline
* font-ubuntu-mono-powerline
* forklift
* gas-mask
* github
* gitup
* goodsync
* googleappengine
* google-drive
* handbrake
* handbrakecli
* imagealpha
* imagemin
* imageoptim
* istat-menus
* java
* macpass
* omnifocus
* omnifocus-clip-o-tron
* omnigraffle
* omnioutliner
* omniplan
* plex-home-theater
* qlcolorcode
* qlimagesize
* qlmarkdown
* qlnetcdf
* qlprettypatch
* qlrest
* qlstephen
* qlvideo
* querious
* quicklook-csv
* quicklook-json
* quicknfo
* quotefix
* rightfont
* rubymine
* seil
* serf
* sigil
* sling
* sonos
* spamsieve
* staruml
* suspicious-package
* teamviewer
* textexpander
* the-escapers-flux
* tower
* transmission
* ttscoff-mmd-quicklook
* ubersicht
* vagrant
* vagrant-manager
* virtualbox
* vlc
* vmware-fusion
* webpquicklook
* webstorm
* witch
* xquartz

##  We Are All Done For Now

Well thats it for now. If you have any tips or ideas to make my dotfiles better in anyway I'm always open for feed back. Thank you for your interest!

### Sources

 - DFM Full Documentation - [Wiki](http://github.com/justone/dotfiles/wiki) | [DFM GitHub](https://github.com/justone/dfm)
 - HomeBrew - [Website](http://brew.sh/)