#!/bin/bash
# run_urxvt_rich                                       JennyM 2019 Malkalech.com

opts=(

  ## common settings
  -geometry 96x32              # geometry
  -sr                          # scrollBar_right
  -st                          # scrollBar_floating
  -scrollstyle plain           # scrollstyle
  #+sb                          # scrollBar - on(default):-sb  off:+sb
  -bc                          # cursorBlink
  -uc                          # cursorUnderline
  -pointerBlank                # pointerBlank
  -vb                          # visualBell
  -sl 3000                     # saveLines
  -fade 40                     # fading

  ## font
  -fn 'xft:DejaVu Sans Mono-9, xft:IPAGothic'
  -letsp -1                    # letterSpace
  #-lsp 0                       # lineSpace

  ## color / opacity
  ## gruvbox-dark https://github.com/morhetz/gruvbox
  -depth       32              # depth
  -color0      '[90]#282828'   # (black)
  -color1      '[90]#cc241d'   # (red)
  -color2      '[90]#98971a'   # (green)
  -color3      '[90]#d79921'   # (yellow)
  -color4      '[90]#458588'   # (blue)
  -color5      '[90]#b16286'   # (magenta)
  -color6      '[90]#689d6a'   # (cyan)
  -color7      '[90]#a89984'   # (white)
  -color8      '[90]#928374'   # (bright black)
  -color9      '[90]#fb4934'   # (bright red)
  -color10     '[90]#b8bb26'   # (bright green)
  -color11     '[90]#fabd2f'   # (bright yellow)
  -color12     '[90]#83a598'   # (bright blue)
  -color13     '[90]#d3869b'   # (bright magenta)
  -color14     '[90]#8ec07c'   # (bright cyan)
  -color15     '[90]#ebdbb2'   # (bright white)
  -fg          '[90]#ebdbb2'   # foreground
  -bg          '[90]#282828'   # background
  -colorIT     '[90]#8ec07c'   # (italic characters)
  -colorBD     '[90]#d5c4a1'   # (bold characters)
  -colorUL     '[90]#83a598'   # (underlined characters)
  -scrollColor '[90]#504945'   # (scrollbar)
  #-troughColor '[90]#3C3836'   # (scrollbar's trough area)

  "$@"
)

urxvtc "${opts[@]}" >/dev/null 2>&1 || {
  [ "$?" -eq 2 ] && urxvtd -q -o -f && urxvtc "${opts[@]}"
}

# http://malkalech.com/urxvt_terminal_emulator
