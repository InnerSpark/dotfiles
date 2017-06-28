#  Spark Dotfiles
___

There has been to many times where I have had to configure a new server or computer from scratch. We all know how long this takes and how painful it can be to try and remember every app, every configuration and every tool we need or use day in and day out on each one of our computers or servers. This repo is here to help with that and to configure each and every one of my environments so that way I can spend more time doing what I love *(UX Design)* and less time configuring and setting up.

##  Getting Started
The first step we need to do is figure out what we are setting up. Are we setting up a new OSX, a web server, a development environment *(ideally this would be the same as your web server)* or something else all together.

The first thing no mater what we are setting up is we need to get our Dotfiles installed from GitHub.

	git clone https://github.com/InnerSpark/dotfiles.git $HOME/.dotfiles

Next lets have DFM install the dotfiles.

	./.dotfiles/bin/dfm install

Ok so now we have our base setup. Wahoo!

##  OSX Setup

If we are setting up a new computer *(OSX)* then the first thing we are going to want to do is it up so that all the features we want and don't want configured on the base os are taken care of. This next script does just that for you.

	./.dotfile/osx/setup.sh

If you winder exactly what this script does, I would recommend opening it up and reading it. If you don't have the time for that, the best way i can describe it is that it runs allot of commands to change config setting in OSX that may or may not be useful.

## HomeBrew

So I personaly use home brew to manage all my packages and applications. This next script will install the software that I use all the time, which allows me from having to go manualy download and install each one of them. In my opinion this thing is a life savor!

	./.dotfiles/homebrew/install.sh

### Install Packages
    brew install $(<~/.dotfiles/homebrew/packages.txt)

### Install Cask Packages
    brew cask install $(<~/.dotfiles/homebrew/cask_packages.txt)

##  We Are All Done For Now

Well thats it for now. If you have any tips or ideas to make my dotfiles better in anyway I'm always open for feed back. Thank you for your interest!

### Sources

 - DFM Full Documentation - [Wiki](http://github.com/justone/dotfiles/wiki) | [DFM GitHub](https://github.com/justone/dfm)
 - HomeBrew - [Website](http://brew.sh/)