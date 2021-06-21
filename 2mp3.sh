#!/bin/bash

wkdir=`mktemp -d`

resolve() {
  mkdir -p $wkdir/`dirname $1`
  local underlined=`echo "$*" | sed 's/ /_/g'`
  echo $wkdir/$underlined.mp3
  #echo $wkdir/$underlined.mp4
}

for f in **/*.{mp4,wav}; do
  [ -f "$f" ] || continue
  [ "`dirname \"$f\"`" = 'origin' ] && continue
  dirname "$f" | grep -i 'bored' > /dev/null && continue
  ffmpeg -i "$f" $* "`resolve ${f%.*}`"
done
echo $wkdir
