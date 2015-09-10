#!/usr/bin/env bash

# Abstract:
#     Script for using MacVim as the default EDITOR.
#
# Author:
#     Ben Spaulding <http://benspaulding.us/>
#
# Details:
#     This script allows MacVim to be the ``EDITOR`` in a more robust way than
#     the ``mvim`` command line tool allows. This is because the ``mvim``
#     command exits immediately after the file arguments are opened, unless the
#     ``-f`` switch is used. However, some tools, such as crontab, fail with a
#     multiple-term ``EDITOR``. This script can be set as the ``EDITOR``,
#     resolving that issue. The ``-c "au VimLeave * maca hide:"`` switch and
#     argument are also used, which returns focus to the referring app (e.g.,
#     Terminal.app) after editing is complete.
#
# Usage:
#     Save this script to somewhere like your ~/bin directory. You can then put
#     something such as the following in your ~/.bashrc file::
#
#         # Set mveditor/MacVim as EDITOR.
#         if [ -f "$HOME/bin/mveditor" ]; then
#             export EDITOR="$HOME/bin/mveditor"
#         else
#             echo "WARNING: Can't find mveditor. Using vim instead."
#             export EDITOR="vim"
#         fi
#

if [ "$(uname)" == "Darwin"  ]; then
    # Do something under Mac OS X platform
    case "$1" in
        *_EDITMSG|*MERGE_MSG|*_TAGMSG )
            if [ -f "`which mvim`" ]; then
                mvim -f -c "au VimLeave * maca hide:" "$@"
            else
                vim "$@"
            fi
            # /usr/local/bin/vim "$1"
            ;;
        *.md )
            /usr/local/bin/mmdc "$1"
            ;;
        *.txt )
            /usr/local/bin/mmdc "$1"
            ;;
        * )
            if [ -f "`which mvim`" ]; then
                mvim -f -c "au VimLeave * maca hide:" "$@"
            else
                vim "$@"
            fi
            ;;
    esac

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux"  ]; then
    # Do something under Linux platform
    case "$1" in
        *_EDITMSG|*MERGE_MSG|*_TAGMSG )
            vim "$@"
            # vim "$1"
            ;;
        *.md )
            mmdc "$1"
            ;;
        *.txt )
            mmdc "$1"
            ;;
        * )
            vim "$@"
            ;;
    esac

elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT"  ]; then
    # Do something under Windows NT platform
    echo "Windows not yet supported"
fi

