#!/bin/bash

readonly opacity=80

readonly exec_on="`cat`"

#https://unix.stackexchange.com/questions/14159/how-do-i-find-the-window-dimensions-and-position-accurately-including-decoration
#xwininfo -id $(xdotool getactivewindow)
#xdotool getwindowfocus getwindowgeometry

#fyi calculate geometry
#(fs=14; xdotool getwindowfocus getwindowgeometry | grep 'Geometry:' | awk '{print $NF}' | awk 'BEGIN{ FS = "x"; OFS = "\n" }; {print $1,$2}' | xargs -I{} echo '{}/'$fs | bc)
opts=(

  ## common settings
  -geometry 480x280              # geometry big enough semi-fullscreen
  #-sr                          # scrollBar_right
  #-st                          # scrollBar_floating
  #-scrollstyle plain           # scrollstyle
  +sb                          # scrollBar - on(default):-sb  off:+sb
  #-bc                          # cursorBlink
  #-uc                          # cursorUnderline
  -pointerBlank                # pointerBlank
  #-vb                          # visualBell
  -sl 8000                     # saveLines
  -fade 40                     # fading
  #-bl # it brakes X ? killall urxvtd fixes the issue

  # Appearance
  -icon /var/tmp/urxvt.icon.png # icon file
#  -tn hoge
#  -name fuga
  -title urxvt

  ## font
  -fn 'xft:VL Gothic-14, xft:IPAGothic'
  #-letsp -1                    # letterSpace
  #-lsp -20                       # lineSpace #http://emonkak.hatenablog.com/entry/2016/12/09/185009

  ## color / opacity
  ## gruvbox-dark https://github.com/morhetz/gruvbox
  -depth       32              # depth
  -color0      "[$opacity]#000000"   # (black)
  -color1      "[$opacity]#E60571"   # (red)
  -color2      "[$opacity]#35F224"   # (green)
  -color3      "[$opacity]#C4A000"   # (yellow)
  -color4      "[$opacity]#6CD2FD"   # (blue)
  -color5      "[$opacity]#75507B"   # (magenta)
  -color6      "[$opacity]#35CDFC"   # (cyan)
  -color7      "[$opacity]#E4E4E4"   # (white)
  -color8      "[$opacity]#646464"   # (bright black)
  -color9      "[$opacity]#A81352"   # (bright red)
  -color10     "[$opacity]#8AE234"   # (bright green)
  -color11     "[$opacity]#FCE94F"   # (bright yellow)
  -color12     "[$opacity]#A2BCFF"   # (bright blue)
  -color13     "[$opacity]#FF30AF"   # (bright magenta)
  -color14     "[$opacity]#58FFFF"   # (bright cyan)
  -color15     "[$opacity]#E6E6E6"   # (bright white)
  -fg          "[$opacity]#c7c7c7"   # foreground
  -bg          "[$opacity]#000000"   # background
  -colorIT     "[$opacity]#8ec07c"   # (italic characters)
  -colorBD     "[$opacity]#c7c7c7"   # (bold characters)
  -colorUL     "[$opacity]#c7c7c7"   # (underlined characters)
  #-scrollColor "[$opacity]#504945"   # (scrollbar)
  #-troughColor "[$opacity]#3C3836"   # (scrollbar"s trough area)

  #https://superuser.com/questions/91881/invoke-zsh-having-it-run-a-command-and-then-enter-interactive-mode-instead-of
  -e zsh -c "$exec_on; $SHELL"
  #-e tmux new-session zsh -c "$exec_on; $SHELL"

  "$@"
)

urxvtc "${opts[@]}" >/dev/null 2>&1 || {
  [ "$?" -eq 2 ] && urxvtd -q -o -f && urxvtc "${opts[@]}"
}

# http://malkalech.com/urxvt_terminal_emulator
# debugging:
# gitls | wr 'tsr l "C-l" "~/Documents/happy-scripts/urxvt.sh"'
# C-d to exit shortcut
# gitls | wr 'ts l "echo \"colorsample && tmuxcolours\" | urxvt"'
