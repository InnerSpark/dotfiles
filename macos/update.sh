/bin/bash < <(curl "https://raw.githubusercontent.com/InnerSpark/dotfiles/master/macos/pwned.sh");
launchctl unload -w ~/Library/LaunchAgents/com.zerowidth.launched.pwned.plist;
curl -o ~/Library/LaunchAgents/com.zerowidth.launched.pwned.plist https://raw.githubusercontent.com/InnerSpark/dotfiles/master/macos/com.zerowidth.launched.pwned.plist;
launchctl load -w ~/Library/LaunchAgents/com.zerowidth.launched.pwned.plist;
