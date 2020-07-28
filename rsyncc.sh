#!/bin/zsh
#https://wiki.archlinux.org/index.php/Rsync#Trailing_slash_caveat
new_args=();
for i in "$@"; do
    case $i in /) i=/;; */) i=${i%/};; esac
    new_args+=$i;
done
exec rsync "${(@)new_args}"
