#!/bin/bash
# Zeller's congruence
# https://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=5&cad=rja&uact=8&ved=0ahUKEwjmmcaH4YTaAhVBE5QKHaI8CHEQFghJMAQ&url=https%3A%2F%2Fqiita.com%2Fbsdhack%2Fitems%2F2884a232bf49dbd7988c&usg=AOvVaw1oE0S8odLmnRf1EPO7hjt3

test $# -ne 3 && exit 1

y=$1; m=$2; d=$3
test $m -lt 3 && y=$(($y - 1)) && m=$(($m + 12))
echo $(($(($y + $y/4 - $y/100 + $y/400 + $(($((13 * $m + 8))/5)) + $d)) % 7))

