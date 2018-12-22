#!/bin/bash

wkdir=`mktemp -d`

resolve() {
  mkdir -p $wkdir/`dirname $1`
  local underlined=`echo "$*" | sed 's/ /_/g'`
  echo $wkdir/$underlined.mp3
}

for f in **/*.{mp4,wav}; do
  [ -f "$f" ] || continue
  ffmpeg -i "$f" $* "`resolve ${f%.*}`"
done
echo $wkdir
