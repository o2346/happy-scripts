#!/bin/bash

wkdir=`mktemp -d`

resolve() {
  mkdir -p $wkdir/`dirname $1`
  local underlined=`echo "$*" | sed 's/ /_/g'`
  echo $wkdir/$underlined.mp3
  #echo $wkdir/$underlined.mp4
}

# use "generate_dummy_mp 3 6" instead of below
#dummy_basename=000_dummy_vlc
#ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 6 -q:a 9 -acodec libmp3lame $wkdir/${dummy_basename}.mp3

for f in **/*.{mp4,wav}; do
  [ -f "$f" ] || continue
  [ "`dirname \"$f\"`" = 'origin' ] && continue
  dirname "$f" | grep -i 'bored' > /dev/null && continue
  ffmpeg -i "$f" $* "`resolve ${f%.*}`"
done

echo $wkdir
