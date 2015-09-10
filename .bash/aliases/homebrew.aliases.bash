# Some aliases for Homebrew

cite 'about-alias'
about-alias 'homebrew abbreviations'

alias bup='brew update && brew upgrade --all'

# TODO: update to check if cask is installed (Linux)
if [ $(uname) = "Darwin" ]; then
    alias bup='brew update && brew cask update && brew upgrade --all && brew cleanup && brew cask cleanup'
elif [ $(uname) = "Linux" ]; then
    alias bup='brew update && brew upgrade --all && brew cleanup'
fi

alias bout='brew outdated'
alias bin='brew install'
alias brm='brew uninstall'
alias bls='brew list'
alias bsr='brew search'
alias binf='brew info'
alias bdr='brew doctor'
