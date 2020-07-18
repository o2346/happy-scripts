#!/bin/bash

readonly url=$1
readonly local_name=~/.files

readonly workdir=`mktemp -d`

cd $workdir

git clone --separate-git-dir=${local_name} $url ./.files || exit 1
cd .files
ls -al
pwd

for f in .??*
do
    case $f in
      .git) continue;;
      .gitignore) continue;;
      .DS_Store) continue;;
      default) :
    esac
    cp -i $(pwd)/$f ~/ 2>&1
done

#git config --bool core.bare true
#git config status.showUntrackedFiles no
#git push --set-upstream origin master
