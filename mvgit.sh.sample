#!/bin/bash

# move a repo from old remote to new one
# this is just for remembering from
# https://qiita.com/TsutomuNakamura/items/058cb851a61bbb1f715b
#
# code below must be modified properly, to be functional
# ~/.ssh/config may also be the one to be taken care of

REPO="something"
git clone --mirror github.old:oldaccount/$REPO
cd $REPO.git
git remote set-url --push origin github:newaccount/$REPO.git
git push --mirror
cd ../

