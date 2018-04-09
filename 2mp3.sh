#!/bin/bash

wkdir=`mktemp -d`

resolve() {
  local underlined=`echo "$*" | sed 's/ /_/g'`
  local name=`basename $underlined`
  echo $wkdir/$name.mp3
}

for f in **/*.{mp4,wav}; do ffmpeg -i "$f" $* "`resolve ${f%.*}`"; done
echo $wkdir
