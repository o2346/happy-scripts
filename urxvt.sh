#!/bin/bash

#readonly opacity=80

if [ -t 0 ]; then
  :
  readonly exec_on=":"
else
  readonly exec_on="`cat`"
fi

readonly dotfile="$HOME/.Xresources"
[ -f "$dotfile" ] && xrdb -remove && xrdb -load $dotfile

if echo $* | grep '\-\-reload' > /dev/null; then
  echo "reloading.." >&2
  #xrdb -load $dotfile
  [ -n "`pidof urxvt`" ] && echo "[WARN] unexpected pidof urxvt = `pidof urxvt`" >&2
  [ -n "`pidof urxvtc`" ] && echo "[WARN] unexpected pidof urxvtc = `pidof urxvtc`" >&2
  kill -1 $(pidof urxvtd)
  exit $?
fi
#
#exit 0

#echo "$@" && exit 0
#https://unix.stackexchange.com/questions/14159/how-do-i-find-the-window-dimensions-and-position-accurately-including-decoration
#xwininfo -id $(xdotool getactivewindow)
#xdotool getwindowfocus getwindowgeometry

#fyi calculate geometry
#(fs=14; xdotool getwindowfocus getwindowgeometry | grep 'Geometry:' | awk '{print $NF}' | awk 'BEGIN{ FS = "x"; OFS = "\n" }; {print $1,$2}' | xargs -I{} echo '{}/'$fs | bc)
opts=(

  ## common settings
  #-geometry 380x180              # geometry big enough semi-fullscreen
  #-sr                          # scrollBar_right
  #-st                          # scrollBar_floating
  #-scrollstyle plain           # scrollstyle
  #+sb                          # scrollBar - on(default):-sb  off:+sb
  #-bc                          # cursorBlink
  #-uc                          # cursorUnderline
  #-pointerBlank                # pointerBlank
  #-vb                          # visualBell
  #-sl 8000                     # saveLines
  #-fade 40                     # fading
  #-bl # it brakes X ? killall urxvtd fixes the issue

  # Appearance
#  -icon /var/tmp/urxvt.icon.png # icon file
  #https://upload.wikimedia.org/wikipedia/commons/thumb/d/da/GNOME_Terminal_icon_2019.svg/768px-GNOME_Terminal_icon_2019.svg.png
#  -tn hoge
#  -name fuga
  #-title urxvt


  ## font
  #-fn 'xft:VL Gothic-14, xft:IPAGothic'
  #-letsp -1                    # letterSpace
  #-lsp -20                       # lineSpace #http://emonkak.hatenablog.com/entry/2016/12/09/185009

  ## color / opacity
  ## gruvbox-dark https://github.com/morhetz/gruvbox
#  -depth       32              # depth
#  -color0      "[$opacity]#000000"   # (black)
#  -color1      "[$opacity]#E60571"   # (red)
#  -color2      "[$opacity]#35F224"   # (green)
#  -color3      "[$opacity]#C4A000"   # (yellow)
#  -color4      "[$opacity]#6CD2FD"   # (blue)
#  -color5      "[$opacity]#75507B"   # (magenta)
#  -color6      "[$opacity]#35CDFC"   # (cyan)
#  -color7      "[$opacity]#E4E4E4"   # (white)
#  -color8      "[$opacity]#646464"   # (bright black)
#  -color9      "[$opacity]#A81352"   # (bright red)
#  -color10     "[$opacity]#8AE234"   # (bright green)
#  -color11     "[$opacity]#FCE94F"   # (bright yellow)
#  -color12     "[$opacity]#A2BCFF"   # (bright blue)
#  -color13     "[$opacity]#FF30AF"   # (bright magenta)
#  -color14     "[$opacity]#58FFFF"   # (bright cyan)
#  -color15     "[$opacity]#E6E6E6"   # (bright white)
#  -fg          "[$opacity]#c7c7c7"   # foreground
#  -bg          "[$opacity]#000000"   # background
#  -colorIT     "[$opacity]#8ec07c"   # (italic characters)
#  -colorBD     "[$opacity]#c7c7c7"   # (bold characters)
#  -colorUL     "[$opacity]#c7c7c7"   # (underlined characters)
  #-scrollColor "[$opacity]#504945"   # (scrollbar)
  #-troughColor "[$opacity]#3C3836"   # (scrollbar"s trough area)

  #https://superuser.com/questions/91881/invoke-zsh-having-it-run-a-command-and-then-enter-interactive-mode-instead-of

  "$@"
  #below must come after above
  #-e zsh -c "$exec_on; wmctrl -x -r urxvt -b add,fullscreen; $SHELL"
  #-e zsh -c "$exec_on; $SHELL"
  #-e tmux new-session zsh -c "$exec_on; $SHELL"
  -e zsh -c "tmux new-session zsh -c \"$exec_on; $SHELL\"; $SHELL"

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
