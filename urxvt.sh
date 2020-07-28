#!/bin/bash
# run_urxvt_rich                                       JennyM 2019 Malkalech.com

readonly opacity=80

#https://unix.stackexchange.com/questions/14159/how-do-i-find-the-window-dimensions-and-position-accurately-including-decoration
#xwininfo -id $(xdotool getactivewindow)
#xdotool getwindowfocus getwindowgeometry
opts=(

  ## common settings
  -geometry 200x300              # geometry
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

  ## font
  -fn 'xft:VL Gothic-14, xft:IPAGothic'
  #-letsp -1                    # letterSpace
  #-lsp -20                       # lineSpace #http://emonkak.hatenablog.com/entry/2016/12/09/185009

  ## color / opacity
  ## gruvbox-dark https://github.com/morhetz/gruvbox
  -depth       32              # depth
  -color0      "[$opacity]#282828"   # (black)
  -color1      "[$opacity]#cc241d"   # (red)
  -color2      "[$opacity]#98971a"   # (green)
  -color3      "[$opacity]#d79921"   # (yellow)
  -color4      "[$opacity]#458588"   # (blue)
  -color5      "[$opacity]#b16286"   # (magenta)
  -color6      "[$opacity]#689d6a"   # (cyan)
  -color7      "[$opacity]#a89984"   # (white)
  -color8      "[$opacity]#928374"   # (bright black)
  -color9      "[$opacity]#fb4934"   # (bright red)
  -color10     "[$opacity]#b8bb26"   # (bright green)
  -color11     "[$opacity]#fabd2f"   # (bright yellow)
  -color12     "[$opacity]#83a598"   # (bright blue)
  -color13     "[$opacity]#d3869b"   # (bright magenta)
  -color14     "[$opacity]#8ec07c"   # (bright cyan)
  -color15     "[$opacity]#ebdbb2"   # (bright white)
  -fg          "[$opacity]#ebdbb2"   # foreground
  -bg          "[$opacity]#000000"   # background
  -colorIT     "[$opacity]#8ec07c"   # (italic characters)
  -colorBD     "[$opacity]#d5c4a1"   # (bold characters)
  -colorUL     "[$opacity]#83a598"   # (underlined characters)
  -scrollColor "[$opacity]#504945"   # (scrollbar)
  #-troughColor "[$opacity]#3C3836"   # (scrollbar"s trough area)

  #-e tmux

  "$@"
)

urxvtc "${opts[@]}" >/dev/null 2>&1 || {
  [ "$?" -eq 2 ] && urxvtd -q -o -f && urxvtc "${opts[@]}"
}

# http://malkalech.com/urxvt_terminal_emulator
# debugging:
# gitls | wr 'tsr l "C-l" "~/Documents/happy-scripts/urxvt.sh"'
# C-d to exit shortcut
