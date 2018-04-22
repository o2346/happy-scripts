#!/bin/zsh

get_hpv() {
  if [ -n "`which $1`" ] && [ $1 = "vmrun" ]; then
    echo "vmx" && return 0
  fi
  if [ -n "`which $1`" ] && [ $1 = "vboxmanage" ]; then
    echo "vbox" && return 0
  fi
  if [ -n "`which vmrun`" ]; then
    echo "vmx" && return 0
  fi
  if [ -n "`which vboxmanage`" ]; then
    echo "vbox" && return 0
  fi
  echo "no_hpv"
}

get_vmname() {
  echo tmp_`LANG=c < /dev/urandom tr -dc a-z0-9 | head -c${1:-6};echo`
}

get_hpv $*
get_vmname
