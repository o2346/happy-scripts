#!/bin/bash
#inspired from
#http://xgarrido.github.io/zsh-utilities/zsh-utilities-functions.html
#https://www.youtube.com/watch?v=gGmBUfMaWMU&t=4m39s
function _extract () {

  if [ -z "$1" -o "$1" = '-h' -o "$1" = '--help' ]; then
    echo "Usage: extract [-option] [file ...]"
    echo
    return 0
  elif [ "$#" != '1' ]; then
    echo 'Error: Acceptable a file on the 1st argument, instead of anything else' >&2
    return 1
  elif [ ! -f "$1" ]; then
    echo 'Error: not a file' >&2
    return 2
  fi

  local readonly base_name="$( basename "$1" )"
  local readonly extract_dir="extracted_$( echo "$base_name" | sed "s/\.${1##*.}//g" )"

  case "$1" in
    (*.tar.gz|*.tgz) tar xvzf "$1" ;;
    (*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$1" ;;
    (*.tar.xz|*.txz) tar --xz --help &> /dev/null \
      && tar --xz -xvf "$1" \
      || xzcat "$1" | tar xvf - ;;
    (*.tar.zma|*.tlz) tar --lzma --help &> /dev/null \
      && tar --lzma -xvf "$1" \
      || lzcat "$1" | tar xvf - ;;
    (*.tar) tar xvf "$1" ;;
    (*.gz) gunzip "$1" ;;
    (*.bz2) bunzip2 "$1" ;;
    (*.xz) unxz "$1" ;;
    (*.lzma) unlzma "$1" ;;
    (*.Z) uncompress "$1" ;;
    (*.zip) unzip "$1" -d $extract_dir ;;
    (*.rar) unrar e -ad "$1" ;;
    (*.7z) 7za x "$1" ;; #https://itsfoss.com/use-7zip-ubuntu-linux/
    (*.deb) # not examined yet
      mkdir -p "$extract_dir/control"
      mkdir -p "$extract_dir/data"
      cd "$extract_dir"; ar vx "../${1}" > /dev/null
      cd control; tar xzvf ../control.tar.gz
      cd ../data; tar xzvf ../data.tar.gz
      cd ..; rm *.tar.gz debian-binary
      cd ..
      ;;
    (*)
      echo "Error: '$1' cannot be extracted" 1>&2
      return 3
      ;;
  esac

  return 0
}

_extract $*
