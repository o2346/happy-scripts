#!/bin/bash

# @(#) Automatically run make when a file changes

# Watchify Make
# usage:
#   wm [Any optons that would be passed to the make]
# Confirmed functional with GNU Make 4.x on macos Sierra or Linux Mint18.x
# modified from http://zgp.org/~dmarti/tips/automatically-run-make/#.WY6eoDeRVhE

# user can add files to be monitored by "make ls" in Makefile
# for example,
#
# .PHONY: ls
# ls: ## list any files user demands
# 	@ls -a | grep "^\."
#
# in this case, any dotfiles located in the same directory with the Makefile also will be monitored
#   though current directory & parent "..","." will be ignored
#   duplicates would be taken care of as uniqe

# DEBUG=0
# debug flag
# wm would print some additional info
# it will be passed to make itself as an argument also
echo $* | grep 'DEBUG=0' > /dev/null
DEBUG=$?

if [ $DEBUG = 0 ]; then
  echo "[WM] DEBUG mode option transmitted"
fi

make_prereqs() {
  # Make "make" figure out what files it's interested in.
  echo "Makefile"
  make -dnr $* | tr ' ' '\n' | \
      grep ".*'.$" | grep -o '\w.*\b' | sed "s/'\.//"
}

prereq_files_verbose() {
  # prerequisites mentioned in a Makefile
  # that are extant files
  for f in `make_prereqs $* | sort -u`; do
    if [ -f $f ]; then
      echo "$f"

      # file names defined in the target source like #include "hoge.h" also should be a target
      # If they ware actually exists.
      # This may cause of slow
      find . -type f -follow -print | sed -e 's/^\.\///g' | while read line; do
        if cat $f | grep $line > /dev/null ; then
          echo "$line"
        fi
      done
    fi
  done
  make ls &> /dev/null
  [ $? = 0 ] && make ls
}

# omit verbose
prereq_files() {
  echo $(prereq_files_verbose | grep -v "^\\.\+$" | sort | uniq)
}

# say something if make say like
isup() {
  make -n | egrep -i '(Nothing to be done for)|(is up to date)'
}

isevent() {
  local expr='('`prereq_files | tr ' ' '|'`')'
  cat - | awk '{print $1}' | egrep "$expr"
  make ls &> /dev/null
  [ $? = 0 ] && make ls
}

# execute what to do if needed
makeif() {
  if test "`isup`"; then
    return 0
  fi
  stdin=`cat -`
  [ $DEBUG = 0 ] && echo $stdin
  if echo $stdin | grep -i "makefile" > /dev/null; then
    make -B $*
    return 0
  fi
  events=`echo $stdin | isevent`
  if [ -n "$events" ] ; then
    make $*
  fi
}

#msec
gettime() {
  #echo "console.log( Date.now() );" | node
  echo "import time; print int(round(time.time() * 1000))" | python
}

TIMEOUT=`gettime`

isTimeout() {
  local now=`gettime`
  if [ "$now" -gt "$TIMEOUT" ]; then
    #echo timeout [ $TIMEOUT ]
    TIMEOUT=$((now + 600))
    return 0
  else
    #echo NOT timeout yet
    return 1
  fi
}

# main func
_wm() {

  echo '[ '`prereq_files | tr ' ' ','`' ]'
  # the first time execution
  make $*

  if [ "$(uname)" = 'Darwin' ]; then
    # you may need to install beforehand
    # brew install make --with-default-names ## you would like newer version
    # brew install fswatch
    fswatch -0 -x -r -m kqueue_monitor ./ | while read -d "" event ; do
      [ -d "$(echo $event | awk '{print $1}')" ] && continue
      isTimeout; [ $? = 0 ] && echo $event | makeif $*
    done
    # https://gerolian.xyz/2015/01/14/1564/
  else
    # https://www.ibm.com/developerworks/jp/linux/library/l-inotify/index.html
    # https://web.chaperone.jp/w/index.php?inotify-tools
    inotifywait -mr -e ATTRIB --format '%w%f %e' ./ | while [ 1 ]; do
      event="";
      while read -t 0.01 line; do
        event=$line
      done
      if [ -n "$event" ]; then
        echo $event | makeif $*
      fi
    done
  fi
  # alternative if inotifywait was unavailable
  # https://qiita.com/tamanobi/items/74b62e25506af394eae5
}

if echo "$-" | grep -q "i"; then
  :
else
  _wm $*
fi
