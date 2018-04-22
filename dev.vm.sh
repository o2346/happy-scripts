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

get_arghpv() {
  for opt in "$@"; do
    if [ "`echo $opt | grep -e --hpv=*`" ]; then
      echo $opt | sed -e 's/--hpv=//'
    fi
  done
}
get_argvname() {
  for opt in "$@"; do
    if [ "`echo $opt | grep -e --name=*`" ]; then
      echo $opt | sed -e 's/--name=//'
    fi
  done
}

newvm() {
  local arghpv=`get_arghpv $*`
  [ -z "`get_hpv $arghpv 2> /dev/null`" ] && echo "no hypervisor found" >&2 && return 1
  local vname=$(get_vmname `get_argvname $*`)
  local new_cmd="new_`get_hpv $arghpv`"
  $new_cmd "$vname" "$1"
}

while getopts n: OPT
do
  case $OPT in
    n)  newvm $OPTARG $*
      exit 0
      ;;
  esac
done

