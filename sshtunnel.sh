#!/bin/bash

#https://discussions.apple.com/thread/250340095?answerId=250644020022#250644020022

echo $@ | grep -E '(\-h|\-\-help)' > /dev/null && echo "
Thanks to
https://discussions.apple.com/thread/250340095?answerId=250644020022#250644020022

usage example:
`basename $0` 4502 4503 80 user@externalhost

in other terminal,
curl localhost:4502
Or go there by any modern browser

Press Ctrl+c to finish
Assuming some server is running on externalhost:4502 as wellas port 4503 and 80.
" && exit 0

readonly userhost=${@: -1}

tunnel() {
  ssh -N -n ${1} ${2}
}

# Ensure remaining tunnels are eliminated at finishing
trap "ps aux | grep -E 'ssh -N -n -L.+localhost' | awk '{print \$2}' | xargs kill" ERR EXIT SIGKILL

lopts="$(echo ${*%${!#}} | awk  'BEGIN{RS=" ";ORS=" "}; {print "-L "$1":localhost:"$1}')"
echo "Digging ssh tunnel toward $userhost" >&2
#ssh is capable to accsept multiple -L options.
ssh -N -n $lopts $userhost

