#!/bin/bash

#https://discussions.apple.com/thread/250340095?answerId=250644020022#250644020022

uname | grep -i 'Darwin' || exit 1

readonly userhost=${@: -1}

tunnel() {
  ssh -N -n -L ${1}:localhost:${1} ${2} &
}

trap "ps aux | grep tunnel" ERR EXIT SIGKILL

echo ${*%${!#}} | tr ' ' '\n' | while read p; do
  tunnel ${p} $userhost
done

