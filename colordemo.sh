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

sixteen() {
  echo -e "\e[39m\\\e[39m Default"
  echo -e "\e[30m\\\e[30m Black"
  echo -e "\e[31m\\\e[31m Red"
  echo -e "\e[32m\\\e[32m Green"
  echo -e "\e[33m\\\e[33m Yellow"
  echo -e "\e[34m\\\e[34m Blue"
  echo -e "\e[35m\\\e[35m Magenta"
  echo -e "\e[36m\\\e[36m Cyan"
  echo -e "\e[37m\\\e[37m Light gray"
  echo -e "\e[90m\\\e[90m Dark gray"
  echo -e "\e[91m\\\e[91m Light red"
  echo -e "\e[92m\\\e[92m Light green"
  echo -e "\e[93m\\\e[93m Light yellow"
  echo -e "\e[94m\\\e[94m Light blue"
  echo -e "\e[95m\\\e[95m Light magenta"
  echo -e "\e[96m\\\e[96m Light cyan"
  echo -e "\e[97m\\\e[97m White"
  echo -e "\e[0m"
}

sixteenbg() {
  echo -e "\e[49m\\\e[49m Default"
  echo -e "\e[40m\\\e[40m Black"
  echo -e "\e[41m\\\e[41m Red"
  echo -e "\e[42m\\\e[42m Green"
  echo -e "\e[43m\\\e[43m Yellow"
  echo -e "\e[44m\\\e[44m Blue"
  echo -e "\e[45m\\\e[45m Magenta"
  echo -e "\e[46m\\\e[46m Cyan"
  echo -e "\e[47m\\\e[47m Light gray"
  echo -e "\e[100m\\\e[100m Dark gray"
  echo -e "\e[101m\\\e[101m Light red"
  echo -e "\e[102m\\\e[102m Light green"
  echo -e "\e[103m\\\e[103m Light yellow"
  echo -e "\e[104m\\\e[104m Light blue"
  echo -e "\e[105m\\\e[105m Light magenta"
  echo -e "\e[106m\\\e[106m Light cyan"
  echo -e "\e[107m\\\e[107m White"
  echo -e "\e[0m"
}

if [ -z "$1" ]; then
  tmuxcolours
elif declare -F | awk '{print $NF}' | grep "^$1$" > /dev/null; then
  $1
else
  tmuxcolours
fi
