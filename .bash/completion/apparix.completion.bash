#  Source: http://micans.org/apparix/bash_apparix
#
#  BASH-style functions
#
#  Name this file for example .bash_apparix in your $HOME directory
#  and put the line 'source $HOME/.bash_apparix' (without quotes)
#  in the file $HOME/.bashrc.
#  If you use the relevant functions, make sure $EDITOR is set
#  to the name of an available editor.


function toot () {
   if test "$3"; then
      file="$(apparix -favour rOl "$1" "$2")/$3"
   elif test "$2"; then
      file="$(apparix -favour rOl "$1")/$2"
   else
      echo "toot tag dir file OR toot tag file"
      return
   fi
   if [[ $? == 0 ]]; then
      $EDITOR $file
   fi
}

function annot () {
   toot $@ ANNOT
}

function todo () {
   toot $@ TODO
}

function clog () {
   toot $@ ChangeLog
}

function note () {
   toot $@ NOTES
}

function ald () {
  if test "$2"; then
    loc=$(apparix -favour rOl "$1" "$2")
  elif test "$1"; then
    loc=$(apparix --try-current-first -favour rOl "$1")
  fi
  if [[ $? == 0 ]]; then
    ls "$loc"
  fi
}

function als () {
  loc=$(apparix -favour rOl "$1")
  if test "$1"; then
    loc=$(apparix -favour rOl "$1")
  fi
  if [[ $? == 0 ]]; then
     if test "$2"; then
       ls "$loc"/$2
    else
       ls "$loc"
    fi
  fi
}

function als1 () {
  if test "$2"; then
    loc=$(apparix -favour rOl "$1" "$2")
  elif test "$1"; then
    loc=$(apparix --try-current-first -favour rOl "$1")
  fi
  if [[ $? == 0 ]]; then
    ls "$loc"
  fi
}


function ae () {
  if test "$2"; then
    loc=$(apparix -favour rOl "$1" "$2")
  elif test "$1"; then
    loc=$(apparix --try-current-first -favour rOl "$1")
  fi
  if [[ $? == 0 ]]; then
    files=$(ls $loc)
    if [[ $? == 0 ]]; then
       $EDITOR $files
    else
      echo "no listing for $loc"
    fi
  fi
}

function whence () {
  if test "$2"; then
    loc=$(apparix -pick $2 "$1")
  elif test "$1"; then
   loc=$(apparix "$1")
  else
    loc=$HOME
  fi
  if [[ $? == 0 ]]; then
    cd "$loc"
  fi
}


function to () {
  true
  if test "$2"; then
    loc=$(apparix --try-current-last -favour rOl "$1" "$2")
  elif test "$1"; then
    if test "$1" == '-'; then
      loc="-"
    else
      loc=$(apparix --try-current-last -favour rOl "$1")
    fi
  else
    loc=$HOME
  fi
  if [[ $? == 0 ]]; then
    cd "$loc"
  fi
}

function bm () {
  if test "$2"; then
    apparix --add-mark "$1" "$2";
  elif test "$1"; then
    apparix --add-mark "$1";
  else
    apparix --add-mark;
  fi
}
function portal () {
  if test "$1"; then
    apparix --add-portal "$1";
  else
    apparix --add-portal;
  fi
}
# function to generate list of completions from .apparixrc
function _apparix_aliases ()
{ cur=$2
  dir=$3
  COMPREPLY=()
  nullglobsa=$(shopt -p nullglob)
  shopt -s nullglob
  if let $(($COMP_CWORD == 1)); then
    # now cur=<apparix mark> (completing on this) and dir='to'
    # Below will complete on subdirectories of current directory. swap if so desired.
    # COMPREPLY=( $( (cat $HOME/.apparix{rc,expand} | grep "\<j," | cut -f2 -d, ; ls -1p | grep '/$' | tr -d /) | grep "\<$cur.*" ) )
    # Below will not complete on subdirectories of current directory. swap if so desired.
    COMPREPLY=( $( cat $HOME/.apparix{rc,expand} | grep "j,.*$cur.*," | cut -f2 -d, ) )
  else
    # now dir=<apparix mark> and cur=<subdirectory-of-mark> (completing on this)
    # or cur=<fileordir> (when bound for example to ae)
    dir=`apparix --try-current-last -favour rOl $dir 2>/dev/null` || return 0
    eval_compreply="COMPREPLY=( $(
      cd "$dir"
      \ls -d $cur* | while read r
      do
        [[ $1 == 'ae' || $1 == 'als' || -d "$r" ]] &&
        [[ $r == *$cur* ]] &&
          echo \"${r// /\\ }\/\"
      done
    ) )"
  eval $eval_compreply
  fi
  $nullglobsa
  return 0
}


# command to register the above to expand when the 'to' command's args are
# being expanded
complete -o nospace -F _apparix_aliases to
complete -o nospace -F _apparix_aliases a
complete -o nospace -F _apparix_aliases ald
complete -o nospace -F _apparix_aliases als
complete -o nospace -F _apparix_aliases ae

export APPARIXLOG=$HOME/.apparixlog

alias via='vi $HOME/.apparixrc'

alias now='cd $(a now)'
#  BASH-style functions
#
#  Name this file for example .bash_apparix in your $HOME directory
#  and put the line 'source $HOME/.bash_apparix' (without quotes)
#  in the file $HOME/.bashrc.
#  If you use the relevant functions, make sure $EDITOR is set
#  to the name of an available editor.


function toot () {
   if test "$3"; then
      file="$(apparix -favour rOl "$1" "$2")/$3"
   elif test "$2"; then
      file="$(apparix -favour rOl "$1")/$2"
   else
      echo "toot tag dir file OR toot tag file"
      return
   fi
   if [[ $? == 0 ]]; then
      $EDITOR $file
   fi
}

function annot () {
   toot $@ ANNOT
}

function todo () {
   toot $@ TODO
}

function clog () {
   toot $@ ChangeLog
}

function note () {
   toot $@ NOTES
}

function ald () {
  if test "$2"; then
    loc=$(apparix -favour rOl "$1" "$2")
  elif test "$1"; then
    loc=$(apparix --try-current-first -favour rOl "$1")
  fi
  if [[ $? == 0 ]]; then
    ls "$loc"
  fi
}

function als () {
  loc=$(apparix -favour rOl "$1")
  if test "$1"; then
    loc=$(apparix -favour rOl "$1")
  fi
  if [[ $? == 0 ]]; then
     if test "$2"; then
       ls "$loc"/$2
    else
       ls "$loc"
    fi
  fi
}

function als1 () {
  if test "$2"; then
    loc=$(apparix -favour rOl "$1" "$2")
  elif test "$1"; then
    loc=$(apparix --try-current-first -favour rOl "$1")
  fi
  if [[ $? == 0 ]]; then
    ls "$loc"
  fi
}


function ae () {
  if test "$2"; then
    loc=$(apparix -favour rOl "$1" "$2")
  elif test "$1"; then
    loc=$(apparix --try-current-first -favour rOl "$1")
  fi
  if [[ $? == 0 ]]; then
    files=$(ls $loc)
    if [[ $? == 0 ]]; then
       $EDITOR $files
    else
      echo "no listing for $loc"
    fi
  fi
}

function whence () {
  if test "$2"; then
    loc=$(apparix -pick $2 "$1")
  elif test "$1"; then
   loc=$(apparix "$1")
  else
    loc=$HOME
  fi
  if [[ $? == 0 ]]; then
    cd "$loc"
  fi
}


function to () {
  true
  if test "$2"; then
    loc=$(apparix --try-current-last -favour rOl "$1" "$2")
  elif test "$1"; then
    if test "$1" == '-'; then
      loc="-"
    else
      loc=$(apparix --try-current-last -favour rOl "$1")
    fi
  else
    loc=$HOME
  fi
  if [[ $? == 0 ]]; then
    cd "$loc"
  fi
}

function bm () {
  if test "$2"; then
    apparix --add-mark "$1" "$2";
  elif test "$1"; then
    apparix --add-mark "$1";
  else
    apparix --add-mark;
  fi
}
function portal () {
  if test "$1"; then
    apparix --add-portal "$1";
  else
    apparix --add-portal;
  fi
}
# function to generate list of completions from .apparixrc
function _apparix_aliases ()
{ cur=$2
  dir=$3
  COMPREPLY=()
  nullglobsa=$(shopt -p nullglob)
  shopt -s nullglob
  if let $(($COMP_CWORD == 1)); then
    # now cur=<apparix mark> (completing on this) and dir='to'
    # Below will complete on subdirectories of current directory. swap if so desired.
    # COMPREPLY=( $( (cat $HOME/.apparix{rc,expand} | grep "\<j," | cut -f2 -d, ; ls -1p | grep '/$' | tr -d /) | grep "\<$cur.*" ) )
    # Below will not complete on subdirectories of current directory. swap if so desired.
    COMPREPLY=( $( cat $HOME/.apparix{rc,expand} | grep "j,.*$cur.*," | cut -f2 -d, ) )
  else
    # now dir=<apparix mark> and cur=<subdirectory-of-mark> (completing on this)
    # or cur=<fileordir> (when bound for example to ae)
    dir=`apparix --try-current-last -favour rOl $dir 2>/dev/null` || return 0
    eval_compreply="COMPREPLY=( $(
      cd "$dir"
      \ls -d $cur* | while read r
      do
        [[ $1 == 'ae' || $1 == 'als' || -d "$r" ]] &&
        [[ $r == *$cur* ]] &&
          echo \"${r// /\\ }\/\"
      done
    ) )"
  eval $eval_compreply
  fi
  $nullglobsa
  return 0
}


# command to register the above to expand when the 'to' command's args are
# being expanded
complete -o nospace -F _apparix_aliases to
complete -o nospace -F _apparix_aliases a
complete -o nospace -F _apparix_aliases ald
complete -o nospace -F _apparix_aliases als
complete -o nospace -F _apparix_aliases ae

export APPARIXLOG=$HOME/.apparixlog

alias via='vi $HOME/.apparixrc'

alias now='cd $(a now)'
#  BASH-style functions
#
#  Name this file for example .bash_apparix in your $HOME directory
#  and put the line 'source $HOME/.bash_apparix' (without quotes)
#  in the file $HOME/.bashrc.
#  If you use the relevant functions, make sure $EDITOR is set
#  to the name of an available editor.


function toot () {
   if test "$3"; then
      file="$(apparix -favour rOl "$1" "$2")/$3"
   elif test "$2"; then
      file="$(apparix -favour rOl "$1")/$2"
   else
      echo "toot tag dir file OR toot tag file"
      return
   fi
   if [[ $? == 0 ]]; then
      $EDITOR $file
   fi
}

function annot () {
   toot $@ ANNOT
}

function todo () {
   toot $@ TODO
}

function clog () {
   toot $@ ChangeLog
}

function note () {
   toot $@ NOTES
}

function ald () {
  if test "$2"; then
    loc=$(apparix -favour rOl "$1" "$2")
  elif test "$1"; then
    loc=$(apparix --try-current-first -favour rOl "$1")
  fi
  if [[ $? == 0 ]]; then
    ls "$loc"
  fi
}

function als () {
  loc=$(apparix -favour rOl "$1")
  if test "$1"; then
    loc=$(apparix -favour rOl "$1")
  fi
  if [[ $? == 0 ]]; then
     if test "$2"; then
       ls "$loc"/$2
    else
       ls "$loc"
    fi
  fi
}

function als1 () {
  if test "$2"; then
    loc=$(apparix -favour rOl "$1" "$2")
  elif test "$1"; then
    loc=$(apparix --try-current-first -favour rOl "$1")
  fi
  if [[ $? == 0 ]]; then
    ls "$loc"
  fi
}


function ae () {
  if test "$2"; then
    loc=$(apparix -favour rOl "$1" "$2")
  elif test "$1"; then
    loc=$(apparix --try-current-first -favour rOl "$1")
  fi
  if [[ $? == 0 ]]; then
    files=$(ls $loc)
    if [[ $? == 0 ]]; then
       $EDITOR $files
    else
      echo "no listing for $loc"
    fi
  fi
}

function whence () {
  if test "$2"; then
    loc=$(apparix -pick $2 "$1")
  elif test "$1"; then
   loc=$(apparix "$1")
  else
    loc=$HOME
  fi
  if [[ $? == 0 ]]; then
    cd "$loc"
  fi
}


function to () {
  true
  if test "$2"; then
    loc=$(apparix --try-current-last -favour rOl "$1" "$2")
  elif test "$1"; then
    if test "$1" == '-'; then
      loc="-"
    else
      loc=$(apparix --try-current-last -favour rOl "$1")
    fi
  else
    loc=$HOME
  fi
  if [[ $? == 0 ]]; then
    cd "$loc"
  fi
}

function bm () {
  if test "$2"; then
    apparix --add-mark "$1" "$2";
  elif test "$1"; then
    apparix --add-mark "$1";
  else
    apparix --add-mark;
  fi
}
function portal () {
  if test "$1"; then
    apparix --add-portal "$1";
  else
    apparix --add-portal;
  fi
}
# function to generate list of completions from .apparixrc
function _apparix_aliases ()
{ cur=$2
  dir=$3
  COMPREPLY=()
  nullglobsa=$(shopt -p nullglob)
  shopt -s nullglob
  if let $(($COMP_CWORD == 1)); then
    # now cur=<apparix mark> (completing on this) and dir='to'
    # Below will complete on subdirectories of current directory. swap if so desired.
    # COMPREPLY=( $( (cat $HOME/.apparix{rc,expand} | grep "\<j," | cut -f2 -d, ; ls -1p | grep '/$' | tr -d /) | grep "\<$cur.*" ) )
    # Below will not complete on subdirectories of current directory. swap if so desired.
    COMPREPLY=( $( cat $HOME/.apparix{rc,expand} | grep "j,.*$cur.*," | cut -f2 -d, ) )
  else
    # now dir=<apparix mark> and cur=<subdirectory-of-mark> (completing on this)
    # or cur=<fileordir> (when bound for example to ae)
    dir=`apparix --try-current-last -favour rOl $dir 2>/dev/null` || return 0
    eval_compreply="COMPREPLY=( $(
      cd "$dir"
      \ls -d $cur* | while read r
      do
        [[ $1 == 'ae' || $1 == 'als' || -d "$r" ]] &&
        [[ $r == *$cur* ]] &&
          echo \"${r// /\\ }\/\"
      done
    ) )"
  eval $eval_compreply
  fi
  $nullglobsa
  return 0
}


# command to register the above to expand when the 'to' command's args are
# being expanded
complete -o nospace -F _apparix_aliases to
complete -o nospace -F _apparix_aliases a
complete -o nospace -F _apparix_aliases ald
complete -o nospace -F _apparix_aliases als
complete -o nospace -F _apparix_aliases ae

export APPARIXLOG=$HOME/.apparixlog

alias via='vi $HOME/.apparixrc'

alias now='cd $(a now)'
