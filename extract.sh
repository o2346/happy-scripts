#!/bin/bash
#inspired http://xgarrido.github.io/zsh-utilities/zsh-utilities-functions.html
function _extract ()
{
  local file_name
  local extract_dir

  if [[ "$1" == "" ]]; then
    echo "Usage: extract [-option] [file ...]"
    echo
  fi

  [ -n "$1" -a -f "$1" ] || return 1

  file_name="$( basename "$1" )"
  extract_dir="$( echo "$file_name" | sed "s/\.${1##*.}//g" )"_extracted

  while [ -n "$1" -a -f "$1" ]; do
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
      (*.7z) 7za x "$1" ;;
      (*.deb)
        mkdir -p "$extract_dir/control"
        mkdir -p "$extract_dir/data"
        cd "$extract_dir"; ar vx "../${1}" > /dev/null
        cd control; tar xzvf ../control.tar.gz
        cd ../data; tar xzvf ../data.tar.gz
        cd ..; rm *.tar.gz debian-binary
        cd ..
        ;;
      (*)
        echo "'$1' cannot be extracted" 1>&2
        return 2
        ;;
    esac

    shift
  done
  return 0
}
_extract $*
