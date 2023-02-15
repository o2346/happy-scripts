#!/bin/bash

#https://discussions.apple.com/thread/250340095?answerId=250644020022#250644020022

readonly userhost=${@: -1}

tunnel() {
  ssh -N -n ${1} ${2}
}

trap "ps aux | grep -E 'ssh -N -n -L.+localhost' | awk '{print \$2}' | xargs kill" ERR EXIT SIGKILL

lopts="$(echo ${*%${!#}} | awk  'BEGIN{RS=" ";ORS=" "}; {print "-L "$1":localhost:"$1}')"
ssh -N -n $lopts $userhost

