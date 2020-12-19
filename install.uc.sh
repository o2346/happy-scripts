#!/bin/bash

#(Unix) User Configurations
# Deploy dotfiles on a remote repo in manner indicated below
#https://wiki.archlinux.org/index.php/Dotfiles
#https://news.ycombinator.com/item?id=11070797
#https://www.atlassian.com/git/tutorials/dotfiles

#before executing, ensure current directory is where you intent to deploy the files
#for instance, $HOME for practical. `mktemp -d` for testing instead

# if any objects were alredy there, it aborts

#Usage:
#curl 'https://raw.githubusercontent.com/o2346/happy-scripts/develop/install.uc.sh' | bash -s - [REMOTE_URL]
#[REMOTE_URL] like gist:xxxx for instance assumined already could be cloned as a bare

#demo:
#cd `mktemp -d` && curl 'https://raw.githubusercontent.com/o2346/happy-scripts/develop/install.uc.sh' | bash -s - https://gist.github.com/o2346/d12142dc810a6b5175607a19ed3c6373
#go to temp dir since you may want sample files to be present on disposable directory instead of important one on a current


readonly url=$1
readonly local_name='.uc'

#if [ -d "$local_name" ]; then
#  echo "WARNING: Removing existing items" >&2
#  git ls-tree HEAD --name-only | xargs rm && .uc `mktemp -d`
#fi

git clone --bare $url $PWD/$local_name || exit 1

cd $local_name
git config status.showUntrackedFiles no

echo "Issue command like below to operate git dedicated for the repo" >&2

if ! git --git-dir=$PWD --work-tree=`dirname $PWD` checkout; then
  echo "Something is wrong. Carefully remove related objects and retry" >&2
  exit 1
fi

echo 'looks fine review the files' >&2
cd ../
ls -altrh | tail

echo "alias config=/usr/bin/git\ --git-dir=$PWD\ --work-tree=`dirname $PWD`" >&2
alias config="/usr/bin/git --git-dir=$PWD --work-tree=`dirname $PWD`"
#https://stackoverflow.com/questions/8514284/bash-how-to-pass-arguments-to-a-script-that-is-read-via-standard-input
#https://stackoverflow.com/a/55081559
