#!/bin/zsh

help() {
  printf "# wrapper script of vmrun or VBoxManage\n"
  printf "usage: vm [OPTONS]\n"
  printf "no args  start vm if any of such objects (like .vmx/.vbox) was found in current directory \n"
  printf "     -h  show this help\n"
  printf "     -i  show info\n"
  printf "     -s  shutdown vm\n"
  printf "     -k  kill vm\n"
  printf "     -D  delete vm\n"
  printf "     -n  [DISTRIBUSION.iso] create new instance from given image\n"
  printf "     --name=[VMNAME_as_you_like] specify name of instance with option -n\n"
  printf "     --hpv=[kind] specify hypervisor with option -n.\n"
  printf "                  One of \"vboxmanage\" \"vmrun\" acceptable\n"
}

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

getramsizemb() {
  if [ "$(uname)" = 'Darwin' ]; then
    #Memory: 16 GB
    system_profiler SPHardwareDataType | grep 'Memory:' | sed -e 's/GB/000/' | tr -dc 0-9
  else
    expr `cat /proc/meminfo | grep 'MemTotal:' | sed -e 's/kb//' | tr -dc 0-9` / 1000
  fi
}

getEthFace() {
  if [ "$(uname)" = 'Darwin' ]; then
    echo "en0"
  else
    itMayBeOneOf=("eth0\nenp3s0")
    echo $itMayBeOneOf | while read line; do
      if ifconfig | grep $line > /dev/null; then
        echo $line
      fi
    done
  fi
}

# https://nakkaya.com/2012/08/30/create-manage-virtualBox-vms-from-the-command-line/
# create new vm of VirtualBox with some spec
# usage:
#  new_vbox VMNAME PATH_TO_LIVECD_DVD.iso
# depends on:
#  vboxmanage
new_vbox() {
  ethface=`getEthFace`

  # http://zeblog.co/?p=390
  if [[ $2 =~ "mint" ]]; then
    local ostype="Ubuntu_64"
  elif [[ $2 =~ "kali" ]]; then
    local ostype="Debian_64"
  elif echo $2 | grep -i "fedora" > /dev/null; then
    local ostype="Fedora_64"
  elif echo $2 | grep -i "cent" > /dev/null; then
    local ostype="RedHat_64"
  elif echo $2 | grep -i "windows" > /dev/null; then
    local ostype="WindowsNT"
  else
    local ostype="Ubuntu_64"
  fi

  #local targetdir="`mktemp -d`/$1"
  #mkdir $targetdir
  local parentdir=`mktemp -d`
  local targetdir=$parentdir/$1

  local uuid=`vboxmanage createvm --register --name "$1" --ostype $ostype --basefolder $parentdir | grep UUID: | sed 's/UUID: //'`

  #vboxmanage createvm --name "$1" --ostype $ostype --basefolder $targetdir
  local memrate=8
  local hostramsize=`getramsizemb`

  vboxmanage modifyvm "$uuid" --memory `expr $hostramsize / $memrate` --acpi on --boot1 dvd \
    --nic1 bridged --bridgeadapter1 $ethface \
    --cpus 2 \
    --clipboard bidirectional \
    --vram 32
  vboxmanage storagectl "$uuid" --name "ide" --add ide

  # I have no idea why they don't allow the same name of vdi created later and saying like "It is collision id" or something.
  # Anyway It will be accepted when it comes with  different name
  hddname="$targetdir/primary.`uuidgen | awk '{print tolower($0)}'| tail -c -5`.vdi"
  vboxmanage createhd --filename "$hddname" --size 18000

  VBoxManage storageattach "$uuid" --storagectl "ide" \
    --port 0 --device 0 --type hdd --medium "$hddname"
  VBoxManage storageattach "$uuid" --storagectl "ide" \
    --port 1 --device 0 --type dvddrive --medium $2
  #vboxmanage modifyvm "$1" --macaddress1 XXXXXXXXXXXX
  #currdir=`pwd`
  cd $targetdir && vm
  echo $targetdir
  #cd $currdir
}

# create new vm of VMWare player with some spec
# usage:
#  new_vmx VMNAME PATH_TO_LIVECD_DVD.iso
# depends on:
#  vmrun
#  repo in gist (means also network)
# Only support player, not for Fusion.
# Fusion7 can't handle the resource files created by newer version of Player which is 12
# And it requires to buy newer one
# Why do I have to do something special further for "Fusion" so foolishly
new_vmx() {
  local HOST="player"

  # Name of predefined resource files
  local srcname="struct_vmx"

  # get predefined resource files
  local getsrc() {
    src="$HOME/Downloads/$srcname"
    if [ -d $src ]; then
      cwd=`pwd`
      cd $src
      git pull > /dev/null
      cd $cwd
    else
      git clone https://gist.github.com/whateverjp/ca42f920f4fab4031a6238f63ca4f29c $src
    fi
    echo $src
  }

  local srcpath=`getsrc`

  # Copy resource files for "instance" from predefined one.
  # src itself is not dedicated to be changed
  local getinstancedir() {
    tmpdir=`mktemp -d`
    mkdir $tmpdir/$1
    cp $srcpath/$srcname*.* $tmpdir/$1
    echo $tmpdir/$1
  }

  local instancedir=`getinstancedir $1`

  # change file name and contents into given name
  # *.vmx supposed to indicate location of liveCD/DVD image that user gave this func
  local getinstance() {
    for file in $instancedir/$srcname.* ; do
      sed -i "s/$srcname/$1/g" $file
    done
    rename "s/$srcname/$1/" $instancedir/*

    vmx="$instancedir/$1.vmx"
    sed -i 's|/dev/null/dummy.iso|'$2'|g' $vmx # ofcourse it must be replaced with proper name..
    echo $vmx
  }

  local VMX=`getinstance $*`
  vmrun -T $HOST start $VMX
  echo $instancedir
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
    if [ "`echo $opt | grep -e '--hpv=*'`" ]; then
      echo $opt | sed -e 's/--hpv=//'
    fi
  done
}

get_argvname() {
  for opt in "$@"; do
    if [ "`echo $opt | grep -e '--name=*'`" ]; then
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

# start Virtual Machine
vm() {

  VMX=`find . | grep -E '\.vmx$'`

  if [ -n "$VMX" ]; then

    if [ "$(uname)" = 'Darwin' ]; then
      HOST="fusion"
    else
      HOST="player"
    fi
    # http://www.japan-secure.com/entry/how_to_add_a_snapshot_function_in_vmware_workstation_player.html
    ENABLED=`grep -E '^scsi0:0.mode = "independent-nonpersistent' $VMX`

    while getopts iskd:DlrSt:R OPT
    do
      case $OPT in
        D)
            vmrun -T $HOST stop $VMX hard
            vmrun -T $HOST deleteVM $VMX
            return 0
            ;;
        i)  vmrun -T $HOST list
            vmrun -T $HOST listSnapshots $VMX true
            echo toolsstate=`vmrun -T $HOST checkToolsState $VMX`
            cat $VMX | grep independent
            return 0
            ;;
        S)  sed -i".org" -e "/^scsi0:0.mode = \"independent-nonpersistent\"$/d" $VMX
            if [ -n "$ENABLED" ]; then
              echo "[Persistent] machine state is being preserved"
            else
              echo "[NONpersistent] machine state will be desposed of at shutdown"
              sed -ie "/^scsi0:0\.fileName/a scsi0:0.mode = \"independent-nonpersistent\"" $VMX
            fi
            return 0
          ;;
        r) echo restart Virtual Machine..
          vmrun -T $HOST reset $VMX hard
          return 0
          ;;
        s) echo halt Virtual Machine..
          vmrun -T $HOST stop $VMX soft
          return 0
          ;;
        k) echo halt Virtual Machine..
          vmrun -T $HOST stop $VMX hard
          return 0
          ;;
        R) echo restore latest snapshot..
          VMSD=`find . | grep -E '\.vmsd$'`
          SNAPSHOT=`cat $VMSD | grep -E 'displayName = ".+"' | sed -e 's/snapshot.\.displayName = "//g' | sed -e 's/"//g' | tail -n 1`
          echo snapshot=$SNAPSHOT
          vmrun -T $HOST revertToSnapshot $VMX $SNAPSHOT
          vmrun -T $HOST start $VMX
          return 0
          ;;
        t) echo take snapshot $OPTARG ..
          vmrun -T $HOST snapshot $VMX $OPTARG
          return 0
          ;;
        d) echo delete snapshot $OPTARG ..
          vmrun -T $HOST deleteSnapshot $VMX $OPTARG
          return 0
          ;;
        l) vmrun -T $HOST listSnapshots $VMX
          return 0
          ;;
      esac
    done

    echo starting $VMX by VMWare Player
    vmrun -T $HOST start $VMX
    return 0
  fi

  VBOX=`find . | grep -E '\.vbox$'`

  if [ -n "$VBOX" ]; then
    VBOXPATH=`pwd`/`echo $VBOX | sed -e 's/^\.\///'`

    while getopts iskrRD OPT
    do
      case $OPT in
        s) echo halt Virtual Machine..
           VBoxManage controlvm $VBOXPATH acpipowerbutton
           return 0
           ;;
        k) echo halt Virtual Machine..
           VBoxManage controlvm $VBOXPATH poweroff
           return 0
           ;;
        r) echo restart Virtual Machine..
           VBoxManage controlvm $VBOXPATH reset
           return 0
           ;;
        R) echo restore snapshot of Virtual Machine..
           VBoxManage controlvm $VBOXPATH poweroff
           VBoxManage snapshot $VBOXPATH restorecurrent
           virtualbox startvm $VBOXPATH
           return 0
           ;;
        # TODO - make drive immutable
        # https://www.virtualbox.org/manual/ch08.html
        # http://qiita.com/heignamerican/items/fe02f61853f0217e238b
        # vboxmanage storageattach pde --storagectl SATA --port 0 --device 0 --type hdd --medium none
        # vboxmanage storageattach pde --storagectl SATA --port 0 --device 0 --type hdd --medium pde.vdi --mtype immutable
        i) VBoxManage showvminfo $VBOXPATH | grep State
           return 0
           ;;
        D) vboxmanage unregistervm $(basename `pwd`) --delete
           return 0
           ;;
      esac
    done
    # https://www.virtualbox.org/manual/ch08.html#vboxmanage-guestcontrol
    # example:
    # VBoxManage -nologo  guestcontrol "`pwd`/win8.vbox" run --exe "c:\\windows\\system32\\ipconfig.exe" --username **** --password "***" -v --wait-stdout --wait-stderr
    echo starting $VBOXPATH by VirtualBox
    # double
    if [ `uname` = 'Darwin' ]; then
      virtualbox startvm "$VBOXPATH"
    elif [ `uname` = 'Linux' ]; then
      printf "linux\n"
      virtualbox startvm $VBOXPATH
    fi
    return 0
  fi

  while getopts hn: OPT
  do
    case $OPT in
      h)  help
          return 0
          ;;
      n)  newvm $OPTARG $*
          exit 0
          ;;
    esac
  done

}

vm $*
