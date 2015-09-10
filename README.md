# Spark's Dotfiles

## Overview

This repo contains a utility ([dfm](https://github.com/justone/dfm)) to help with managing and updating of my dotfiles. Please continue reading for instructions on how to use them.

## Using this repo

### Setup DFM

First, fork this repo.

Then, add your dotfiles:

    $ git clone git@github.com:username/dotfiles.git .dotfiles
    $ cd .dotfiles
    $  # edit files
    $  # edit files
    $ git push origin master

Finally, to install your dotfiles onto a new system:

    $ cd $HOME
    $ git clone git@github.com:username/dotfiles.git .dotfiles
    $ ./.dotfiles/bin/dfm install # creates symlinks to install files
    

#### DFM Full documentation

For more information, check out the [wiki](http://github.com/justone/dotfiles/wiki).

You can also run <tt>dfm --help</tt>.

### Run HomeBrew script

	$ ./.dotfiles/homebrew/install.sh

### Run OS X Script

	$ ./.dotfiles/osx/setup.sh