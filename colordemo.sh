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
