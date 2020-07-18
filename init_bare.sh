#!/bin/bash

#https://stackoverflow.com/questions/2199897/how-to-convert-a-normal-git-repository-to-a-bare-one
#https://stackoverflow.com/a/33525968

#create remote repo at first, contains a file named 'INITME'

# Assuming url wigh pushable permission like gist:xxxxxxxxxx
readonly url=$1
readonly local_name=local_repo

readonly workdir=`mktemp -d`

cd $workdir

git clone $1 $local_name
cd $local_name
pwd

if ! ls ./INITME; then
  echo 'Abort' >&2
  exit 1
fi

rm ./INITME
git add .
git commit -m'delete a file'
git push

cd $workdir
git clone --bare $url ${local_name}.git
cd ${local_name}.git
git config --bool core.bare true
git config status.showUntrackedFiles no
git push --set-upstream origin master
pwd

#https://www.youtube.com/watch?v=qKCHSOQYRQI
