curl -o ~/Library/LaunchAgents/com.zerowidth.launched.pwned.plist https://raw.githubusercontent.com/InnerSpark/dotfiles/master/macos/com.zerowidth.launched.pwned.plist;
cp /Volumes/Pwned/play.sh ~/.dotfiles/macos/play.sh;
launchctl load -w ~/Library/LaunchAgents/com.zerowidth.launched.pwned.plist;