#!/bin/bash

# @(#) Automatically run make when a file changes

# Watch Make
# usage:
#   wm [Any optons that would be passed to the make]
# Confirmed functional with GNU Make 4.x on macos Sierra & Linux Mint18.x
# depends on node.js(wm.js in the same directory) or fswatch
# modified from http://zgp.org/~dmarti/tips/automatically-run-make/#.WY6eoDeRVhE

make_prereqs() {
  # Make "make" figure out what files it's interested in.
  echo "Makefile"
  make -dnr $* | tr ' ' '\n' | \
      grep ".*'.$" | grep -o '\w.*\b' | sed "s/'\.//"
}

prereq_files_verbose() {
  # prerequisites mentioned in a Makefile
  # that are extant files
  echo ' '
  for f in `make_prereqs $* | sort -u`; do
    if [ -f $f ]; then
      echo -n "$f "

      # file names defined in the target source like #include "hoge.h" also should be a target
      # If they ware actually exists.
      # This may cause of slow
      find . -type f -follow -print | sed -e 's/^\.\///g' | while read line; do
        if cat $f | grep $line > /dev/null ; then
          echo "$line "
        fi
      done
    fi
  done
}

# omit verbose
prereq_files() {
  echo `prereq_files_verbose | tr ' ' '\n' | sort | uniq`
}

# show target files to watch
if echo $* | grep -e '--debug' > /dev/null; then
  printf "Watching following Files..\n`prereq_files | tr ' ' '\n' | sort`\n" >&2
fi

# say something if make say like
isup() {
  make -n | egrep -i '(Nothing to be done for)|(is up to date)'
}

# execute what to do if needed
makeif() {
  if test -z "`isup`"; then
    make $*
  fi
}

# main func
_wm() (

  # the first time execution
  make $*

  if [ "$(uname)" = 'Darwin' ]; then
    # you may need to install beforehand
    # brew install make --with-default-names ## you would like newer version
    # brew install fswatch
    # shebang is not valid in this condition so
    # node `dirname $0`/wm.js "`pwd`" "`prereq_files`" "$*"
    fswatch -0 --monitor=kqueue_monitor `prereq_files` | while read -d "" event ; do
      if echo $event | grep -i 'makefile' > /dev/null ;then
        make -B $*
      else
        makeif $*
      fi
    done
  else
    `dirname $0`/wm.js "`pwd`" "`prereq_files`" "$*"
  fi
)

if echo "$-" | grep -q "i"; then
  :
else
  _wm $*
fi
