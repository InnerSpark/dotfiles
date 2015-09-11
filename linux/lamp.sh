echo "This script will setup a lamp based server"

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

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
  ninja
  pandoc
  pandoc-citeproc
  par
  pdf2htmlex
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
  
echo "Installing binaries..."
brew install ${binaries[@]}

# Install and setup mySQL
echo "Installing mySQl"
echo "export PATH=\$(echo \$PATH | sed 's|/usr/local/bin||; s|/usr/local/sbin||; s|::|:|; s|^:||; s|\(.*\)|/usr/local/bin:/usr/local/sbin:\1|')" >> ~/.bash_profile && source ~/.bash_profile

brew install -v mysql
 
cp -v $(brew --prefix mysql)/support-files/my-default.cnf $(brew --prefix mysql)/my.cnf
 
cat >> $(brew --prefix mysql)/my.cnf <<'EOF'
# Echo & Co. changes
max_allowed_packet = 2G
innodb_file_per_table = 1
EOF
 
sed -i '' 's/^# \(innodb_buffer_pool_size\)/\1/' $(brew --prefix mysql)/my.cnf

echo "Starting mySQL"
[ ! -d ~/Library/LaunchAgents ] && mkdir -v ~/Library/LaunchAgents
 
[ -f $(brew --prefix mysql)/homebrew.mxcl.mysql.plist ] && ln -sfv $(brew --prefix mysql)/homebrew.mxcl.mysql.plist ~/Library/LaunchAgents/
 
[ -e ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist ] && launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist

# Installin Apache2
sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null

brew tap homebrew/dupes
brew tap homebrew/apache

echo "Installing Apache2"
brew install -v httpd22 --with-brewed-openssl

[ ! -d ~/Sites ] && mkdir -pv ~/Sites
 
touch ~/Sites/httpd-vhosts.conf
 
USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F": " '{print $2}') cat >> $(brew --prefix)/etc/apache2/2.2/httpd.conf <<EOF
# Include our VirtualHosts
Include ${USERHOME}/Sites/httpd-vhosts.conf
EOF

[ ! -d ~/Sites/logs ] && mkdir -pv ~/Sites/logs

USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F": " '{print $2}') cat > ~/Sites/httpd-vhosts.conf <<EOF
#
# Use name-based virtual hosting.
#
NameVirtualHost *:80
 
#
# Set up permissions for VirtualHosts in ~/Sites
#
<Directory "${USERHOME}/Sites">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    Order allow,deny
    Allow from all
</Directory>
 
# For http://localhost in the users' Sites folder
<VirtualHost _default_:80>
    ServerName localhost
    DocumentRoot "${USERHOME}/Sites"
</VirtualHost>
 
#
# VirtualHosts
#
 
## Manual VirtualHost template
#<VirtualHost *:80>
#  ServerName project.dev
#  CustomLog "${USERHOME}/Sites/logs/project.dev-access_log" combined
#  ErrorLog "${USERHOME}/Sites/logs/project.dev-error_log"
#  DocumentRoot "${USERHOME}/Sites/project.dev"
#</VirtualHost>
 
#
# Automatic VirtualHosts
# A directory at ${USERHOME}/Sites/webroot can be accessed at http://webroot.dev
# In Drupal, uncomment the line with: RewriteBase /
 
# This log format will display the per-virtual-host as the first field followed by a typical log line
LogFormat "%V %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combinedmassvhost
 
# Auto-VirtualHosts with .dev
<VirtualHost *:80>
  ServerName dev
  ServerAlias *.dev
 
  CustomLog "${USERHOME}/Sites/logs/dev-access_log" combinedmassvhost
  ErrorLog "${USERHOME}/Sites/logs/dev-error_log"
 
  VirtualDocumentRoot ${USERHOME}/Sites/%-2+
</VirtualHost>
 
# Auto-VirtualHosts with xip.io
<VirtualHost *:80>
  ServerName xip
  ServerAlias *.xip.io
 
  CustomLog "${USERHOME}/Sites/logs/dev-access_log" combinedmassvhost
  ErrorLog "${USERHOME}/Sites/logs/dev-error_log"
 
  VirtualDocumentRoot ${USERHOME}/Sites/%-7+
</VirtualHost>
EOF

sudo bash -c 'export TAB=$'"'"'\t'"'"'
cat > /Library/LaunchDaemons/co.echo.httpdfwd.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
${TAB}<key>Label</key>
${TAB}<string>co.echo.httpdfwd</string>
${TAB}<key>ProgramArguments</key>
${TAB}<array>
${TAB}${TAB}<string>sh</string>
${TAB}${TAB}<string>-c</string>
${TAB}${TAB}<string>ipfw add fwd 127.0.0.1,8080 tcp from any to me dst-port 80 in &amp;&amp; sysctl -w net.inet.ip.forwarding=1</string>
${TAB}</array>
${TAB}<key>RunAtLoad</key>
${TAB}<true/>
${TAB}<key>UserName</key>
${TAB}<string>root</string>
</dict>
</plist>
EOF'

echo "starting apache2"
sudo launchctl load -w /Library/LaunchDaemons/co.echo.httpdfwd.plist

# Installing PHP
echo "Installing php"
brew tap homebrew/php
brew install -v php55 --homebrew-apxs --with-apache

cat >> $(brew --prefix)/etc/apache2/2.2/httpd.conf <<EOF
# Send PHP extensions to mod_php
AddHandler php5-script .php
AddType text/html .php
DirectoryIndex index.php index.html
EOF

sed -i '-default' "s|^;\(date\.timezone[[:space:]]*=\).*|\1 \"$(sudo systemsetup -gettimezone|awk -F": " '{print $2}')\"|; s|^\(memory_limit[[:space:]]*=\).*|\1 256M|; s|^\(post_max_size[[:space:]]*=\).*|\1 200M|; s|^\(upload_max_filesize[[:space:]]*=\).*|\1 100M|; s|^\(default_socket_timeout[[:space:]]*=\).*|\1 600|; s|^\(max_execution_time[[:space:]]*=\).*|\1 300|; s|^\(max_input_time[[:space:]]*=\).*|\1 600|;" $(brew --prefix)/etc/php/5.5/php.ini

USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F": " '{print $2}') cat >> $(brew --prefix)/etc/php/5.5/php.ini <<EOF
; PHP Error log
error_log = ${USERHOME}/Sites/logs/php-error_log
EOF

touch $(brew --prefix php55)/lib/php/.lock && chmod 0644 $(brew --prefix php55)/lib/php/.lock

brew install -v php55-opcache

sed -i '' "s|^\(opcache\.memory_consumption=\)[0-9]*|\1256|;" $(brew --prefix)/etc/php/5.5/conf.d/ext-opcache.ini


echp "All Done!"
ln -sfv $(brew --prefix httpd22)/homebrew.mxcl.httpd22.plist ~/Library/LaunchAgents
 
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.httpd22.plist
