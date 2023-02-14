#!/bin/bash

#https://discussions.apple.com/thread/250340095?answerId=250644020022#250644020022

uname | grep -i 'Darwin' || exit 1

readonly userhost=${@: -1}

tunnel() {
  ssh -N -n ${1} ${2}
  #${1}:localhost:${1}
}

trap "ps aux | grep -E 'ssh -N -n -L.+localhost' | awk '{print \$2}' | xargs kill" ERR EXIT SIGKILL

#echo ${*%${!#}} | tr ' ' '\n' | while read p; do
#  tunnel ${p} $userhost
#done
tunnel $(echo ${*%${!#}} | awk  'BEGIN{RS=" ";ORS=" "}; {print "-L "$1":localhost:"$1}') $userhost

