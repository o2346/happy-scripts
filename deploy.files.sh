#!/bin/bash

#Usage:
#curl 'https://raw.githubusercontent.com/o2346/happy-scripts/develop/deploy.files.sh' | bash -s - gist:xxxx
#gist:xxxx is a example url

# Deploy dotfiles in a manner indicated below
#https://wiki.archlinux.org/index.php/Dotfiles
#https://news.ycombinator.com/item?id=11070797

readonly url=$1
readonly local_name=.files

readonly workdir=`mktemp -d`

cd $workdir

git clone --separate-git-dir=$HOME/${local_name} $url $PWD/.files || exit 1
cd $PWD/.files

echo "Publishing dotfiles into $HOME but will not overwrite existing ones" >&2
ls $workdir/.files/.??* | grep -v git | xargs -I{} cp -vn {} ~/

cd $HOME/$local_name
git config status.showUntrackedFiles no
git push --set-upstream origin master
git --git-dir=$HOME/$local_name --work-tree=$HOME pull

echo 'alias config=/usr/bin/git\ --git-dir=$HOME/'$local_name'\ --work-tree=$HOME' >&2

#https://stackoverflow.com/questions/8514284/bash-how-to-pass-arguments-to-a-script-that-is-read-via-standard-input
