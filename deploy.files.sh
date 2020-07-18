#!/bin/bash

# Deploy dotfiles in a manner indicated below
#https://wiki.archlinux.org/index.php/Dotfiles
#https://news.ycombinator.com/item?id=11070797

readonly url=$1
readonly local_name=Documents/.files

readonly workdir=`mktemp -d`

cd $workdir

git clone --separate-git-dir=$HOME/${local_name} $url ./.files || exit 1
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
    [ -f ~/$f ] || continue
    cp -i $(pwd)/$f ~/ 2>&1
done

cd $HOME/$local_name
#git config --bool core.bare true
git config status.showUntrackedFiles no
git push --set-upstream origin master

echo 'alias config=/usr/bin/git\ --git-dir=$HOME/'$local_name'\ --work-tree=$HOME' >&2
