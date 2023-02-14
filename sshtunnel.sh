#!/bin/bash

#https://discussions.apple.com/thread/250340095?answerId=250644020022#250644020022

uname | grep -i 'Darwin' || exit 1

readonly userhost=${@: -1}

tunnel() {
  ssh -N -n -L ${port}:localhost:${port} ${userhost} &
}

trap "ps aux | grep tunnel" ERR EXIT SIGKILL

echo ${*%${!#}} | tr ' ' '\n' | xargs -I{} tunnel {} $userhost

