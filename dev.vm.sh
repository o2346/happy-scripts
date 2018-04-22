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
}

new_vmx() {
  echo "vmx called $1 $2"
}
new_vbox() {
  echo "vbox called $1 $2"
}

get_vmname() {
  if [ -n "$1" ]; then
    echo $1
    return 0
  fi
  echo tmp_`LANG=c < /dev/urandom tr -dc a-z0-9 | head -c${1:-6};echo`
}

newvm() {
  [ -z "`get_hpv $3 2> /dev/null`" ] && echo "no hypervisor found" >&2 && return 1
  local new_cmd="new_`get_hpv $3`"
  local vmname=$1
  local iso=$2
  $new_cmd "$vmname" "$iso"
}

newvm $*

