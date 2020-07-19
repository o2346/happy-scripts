#!/bin/bash

#Usage:
#curl 'https://raw.githubusercontent.com/o2346/happy-scripts/develop/deploy.files.sh' | bash -s - gist:xxxx
#gist:xxxx is a remote url, assumined already could be cloned as a bare

# Deploy dotfiles in a manner indicated below
#https://wiki.archlinux.org/index.php/Dotfiles
#https://news.ycombinator.com/item?id=11070797
#https://www.atlassian.com/git/tutorials/dotfiles

readonly url=$1
readonly local_name=.files

readonly workdir=`mktemp -d`

cd $workdir

git clone --separate-git-dir=$HOME/${local_name} $url $PWD/.files || exit 1

cd $HOME/$local_name
#git --git-dir=$HOME/$local_name --work-tree=$HOME checkout .
git config status.showUntrackedFiles no
git push --set-upstream origin master
#git --git-dir=$HOME/$local_name --work-tree=$HOME pull

echo "Issue following commands" >&2
echo 'alias config=/usr/bin/git\ --git-dir=$HOME/'$local_name'\ --work-tree=$HOME' >&2
echo "config checkout ." >&2

#config checkout .
#https://dev.classmethod.jp/articles/git-reset-and-git-checkout/
#or
#echo 'git --git-dir=$HOME/$local_name --work-tree=$HOME checkout .'

#https://stackoverflow.com/questions/8514284/bash-how-to-pass-arguments-to-a-script-that-is-read-via-standard-input
