#!/bin/bash

# --------------------------------------
# Google search from terminal
# --------------------------------------
# http://unix.stackexchange.com/questions/159166/can-i-pass-commands-to-vimperator-firefox-through-the-command-line
ggr(){
  if [ $(echo $1 | egrep "^-[cfs]$") ]; then
    local opt="$1"
    shift
  fi
  local opt="safe=off&num=16"
  local queries="&q=${*// /+}"
  local noises="+-weblio.jp+-matome.naver.jp+-cookpad.com+-itpro.nikkeibp.co.jp+-rakuten.co.jp"
  local url="https://www.google.co.jp/search?${opt}${queries}${noises}"
  if [ "$(uname)" = 'Darwin' ]; then
    local app="/Applications"
    local c="${app}/Google Chrome.app"
    local f="${app}/Firefox.app"
    local s="${app}/Safari.app"
    case ${opt} in
      "-c")   open "${url}" -a "$c";;
      "-f")   open "${url}" -a "$f";;
      "-s")   open "${url}" -a "$s";;
      *)      open "${url}";;
    esac
  else
    firefox $url
  fi
}

ggr $*
