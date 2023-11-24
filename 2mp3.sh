#!/bin/bash

wkdir=`mktemp -d`

resolve() {
  local underlined=`echo "$*" | sed 's/ /_/g'`
  local prefixnum=$(printf "%03d\\n" $(seq 999 | shuf | head -n1))
  printf "$wkdir/${prefixnum}_${underlined}.mp3"
  #echo $wkdir/$underlined.mp4
}

# same as "generate_dummy_mp 3 6" instead of below
dummy_basename=000_dummy_vlc
ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 6 -q:a 9 -acodec libmp3lame $wkdir/${dummy_basename}.mp3

#for f in *.{mp4,wav}; do
ls -- *.{mp4,wav} | shuf | while read mf; do
  #[ -f "$f" ] || continue
  #[ "`dirname \"$f\"`" = 'origin' ] && continue
  #dirname "$f" | grep -i 'bored' > /dev/null && continue
  #https://unix.stackexchange.com/a/36363
  ffmpeg -i "${mf}" "`resolve ${mf%.*}`" < /dev/null
  #echo "`resolve ${f%.*}`"
done

#cd $wkdir
##https://www.cyberciti.biz/faq/linux-list-just-directories-or-directory-names/
#ls -d */ | xargs -I{} cp -avu *.mp3 {}

echo $wkdir
