#!/bin/bash

#https://superuser.com/questions/285381/how-does-the-tmux-color-palette-work
tmuxcolours() {
  local remainder=`tput cols | xargs -I{} echo "{} / 20" | bc `
  for i in {0..255}; do
    printf "\x1b[38;5;${i}mcolour${i}\x1b[0m "
    echo "(($i + 1) % $remainder ) == 0" | bc | xargs -I{} [ "{}" = '1' ] && echo
  done | column -t
}

# http://qiita.com/dojineko/items/49aa30018bb721b0b4a9
colorsample() {
  for fore in `seq 29 36`; do
    printf "\e[${fore}m \\\e[${fore}m \e[m\n";
    for mode in `seq 1 3`; do
      printf "\e[${fore};${mode}m \\\e[${fore};${mode}m \e[m";
      for back in `seq 1 5`; do
        printf "\e[${fore};${back};${mode}m \\\e[${fore};${back};${mode}m \e[m";
      done
      echo
    done
    echo
  done
}

#https://misc.flogisoft.com/bash/tip_colors_and_formatting

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.
 
#Background
colors_and_formatting() {
  for clbg in {40..47} {100..107} 49 ; do
    #Foreground
    for clfg in {30..37} {90..97} 39 ; do
      #Formatting
      for attr in 0 1 2 4 5 7 ; do
        #Print the result
        echo -en "\e[${attr};${clbg};${clfg}m ^[${attr};${clbg};${clfg}m \e[0m"
      done
      echo #Newline
    done
  done
}

256-colors() {
  # This program is free software. It comes without any warranty, to
  # the extent permitted by applicable law. You can redistribute it
  # and/or modify it under the terms of the Do What The Fuck You Want
  # To Public License, Version 2, as published by Sam Hocevar. See
  # http://sam.zoy.org/wtfpl/COPYING for more details.
   
  for fgbg in 38 48 ; do # Foreground / Background
      for color in {0..255} ; do # Colors
          # Display the color
          printf "\e[${fgbg};5;%sm  %3s  \e[0m" $color $color
          # Display 6 colors per lines
          if [ $((($color + 1) % 6)) == 4 ] ; then
              echo # New line
          fi
      done
      echo # New line
  done
}

