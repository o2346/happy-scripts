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
readonly gitoption="--git-dir=$PWD --work-tree=`dirname $PWD`"
echo $gitoption

echo "Issue command like below to operate git dedicated for the repo" >&2

if ! git --git-dir=$PWD --work-tree=`dirname $PWD` checkout; then
  echo "Something is wrong. Carefully remove related objects and retry" >&2
  exit 1
fi

echo 'looks fine review the files' >&2
cd ../
ls -altrh | tail

echo $gitoption
#git $gitoption branch

#https://stackoverflow.com/questions/5341077/git-doesnt-show-how-many-commits-ahead-of-origin-i-am-and-i-want-it-to
#https://stackoverflow.com/questions/37669297/why-doesnt-my-git-status-show-me-whether-im-up-to-date-with-my-remote-counterp
#[Actual Solution](https://stackoverflow.com/a/11267065)
git $gitoption remote remove origin
git $gitoption remote add origin $url
git $gitoption fetch
git $gitoption branch --set-upstream-to origin/master
git $gitoption branch -r
git $gitoption remote show origin

#https://git-scm.com/book/it/v2/Git-Basics-Working-with-Remotes

#https://stackoverflow.com/questions/8514284/bash-how-to-pass-arguments-to-a-script-that-is-read-via-standard-input
#https://stackoverflow.com/a/55081559
