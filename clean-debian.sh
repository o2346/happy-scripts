#!/bin/bash

#https://fedingo.com/how-to-clean-up-disk-space-in-linux/
sudo apt clean
sudo apt autoclean
sudo apt autoremove

df -h
cat <(du ~/) <(du ~/**/*) <(du ~/**/*.*) | sort -n | tail

#https://askubuntu.com/questions/314723/why-is-the-xsession-errors-old-file-so-big
#https://forums.bunsenlabs.org/viewtopic.php?id=6885
#https://www.daniloaz.com/en/how-to-prevent-the-xsession-errors-file-from-growing-to-huge-size/
#https://xr0038.hatenadiary.jp/entry/20120911/1347347189
rm ~/.xsession-errors.old
cd
ln -s /tmp/.xsession-errors.old

