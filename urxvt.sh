#!/bin/bash


if [ -t 0 ]; then
  :
  readonly exec_on=":"
else
  readonly exec_on="`cat`"
fi

readonly dotfile="$HOME/.Xresources"
[ -f "$dotfile" ] && xrdb -remove && xrdb -load $dotfile
#[ -f "$dotfile" ] && make resource_urxvt

if echo $* | grep '\-\-reload' > /dev/null; then
  echo "reloading.." >&2
  [ -n "`pidof urxvt`" ] && echo "[WARN] unexpected pidof urxvt = `pidof urxvt`" >&2
  [ -n "`pidof urxvtc`" ] && echo "[WARN] unexpected pidof urxvtc = `pidof urxvtc`" >&2
  kill -1 $(pidof urxvtd)
  exit $?
fi

#echo "$@" && exit 0
#https://unix.stackexchange.com/questions/14159/how-do-i-find-the-window-dimensions-and-position-accurately-including-decoration
#xwininfo -id $(xdotool getactivewindow)
#xdotool getwindowfocus getwindowgeometry

#if screen-256color; urxvt
#if xterm-256color gnome term

#fyi calculate geometry
#(fs=14; xdotool getwindowfocus getwindowgeometry | grep 'Geometry:' | awk '{print $NF}' | awk 'BEGIN{ FS = "x"; OFS = "\n" }; {print $1,$2}' | xargs -I{} echo '{}/'$fs | bc)
opts=(

  #https://superuser.com/questions/91881/invoke-zsh-having-it-run-a-command-and-then-enter-interactive-mode-instead-of

  "$@"

  #below must come after above
  #close immidiately with tmux
  -e tmux new-session zsh -c "$exec_on; $SHELL"
  #remain terminal without tmux
  #-e zsh -c "tmux new-session zsh -c \"$exec_on; $SHELL\"; $SHELL"

  #-e zsh -c "$exec_on; wmctrl -x -r urxvt -b add,fullscreen; $SHELL"
  #-e zsh -c "$exec_on; $SHELL"
  #-e zsh -c "$SHELL"

  #https://www.reddit.com/r/linuxmint/comments/736wta/how_to_make_urxvt_terminal_emulator_always_in/
)


urxvtcd "${opts[@]}"
#urxvtc "${opts[@]}" > /dev/null 2>&1
#if [ $? -eq 2 ]; then
#  urxvtd -q -o -f && urxvtc "${opts[@]}"
#fi
# http://malkalech.com/urxvt_terminal_emulator
# debugging:
# gitls | wr 'tsr l "C-l" "~/Documents/happy-scripts/urxvt.sh"'
# C-d to exit shortcut
# gitls | wr 'ts l "echo \"colorsample && tmuxcolours\" | urxvt"'

#https://wiki.archlinux.org/index.php/multihead
#urxvt -geometry 158x34+0+900
#urxvt -geometry 320x220+0+0
#https://stackoverflow.com/questions/9783198/how-to-make-rxvt-start-as-fullscreen
