#!/bin/bash

#(Unix) User Configurations
# Deploy dotfiles on a remote repo in manner indicated below
#https://wiki.archlinux.org/index.php/Dotfiles
#https://news.ycombinator.com/item?id=11070797
#https://www.atlassian.com/git/tutorials/dotfiles

#Usage:
#curl 'https://raw.githubusercontent.com/o2346/happy-scripts/develop/install.uc.sh' | bash -s - [REMOTE_URL]
#[REMOTE_URL] like gist:xxxx foe instance assumined already could be cloned as a bare
#demo:
#curl 'https://raw.githubusercontent.com/o2346/happy-scripts/develop/install.uc.sh' | bash -s - https://gist.github.com/o2346/d12142dc810a6b5175607a19ed3c6373

readonly url=$1
readonly local_name='.uc'

readonly workdir=`mktemp -d`

cd $workdir

git clone --separate-git-dir=$HOME/${local_name} $url $PWD/.uc || exit 1

cd $HOME/$local_name
#git --git-dir=$HOME/$local_name --work-tree=$HOME checkout .
git config status.showUntrackedFiles no
git push --set-upstream origin master
#git --git-dir=$HOME/$local_name --work-tree=$HOME pull

echo "Issue following commands" >&2
echo 'alias .uc=/usr/bin/git\ --git-dir=$HOME/'$local_name'\ --work-tree=$HOME' >&2
echo ".uc checkout ." >&2

#After successful '.uc' command would be available behaves as special git command

#https://dev.classmethod.jp/articles/git-reset-and-git-checkout/
#or
#echo 'git --git-dir=$HOME/$local_name --work-tree=$HOME checkout .'

#https://stackoverflow.com/questions/8514284/bash-how-to-pass-arguments-to-a-script-that-is-read-via-standard-input
