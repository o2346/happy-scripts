#!/bin/zsh

help() {
  printf "# wrapper script of Virtual Machines Operation\n"
  printf "# wraps vmrun VBoxManage, quemu, aws ec2\n"
  printf "usage: vm [OPTONS]\n"
  printf "no args  start vm if any of such objects (like .vmx/.vbox) was found in current directory \n"
  printf "      note that disk will be immutable, all changes within running will be disposed of (except vboxmanage)\n"
  printf "  -m  temporarily make disk mutable and run \n"
  printf "  -h  show this help\n"
  printf "  -i  show info\n"
  printf "  -s  shutdown vm\n"
  printf "  -k  kill vm\n"
  printf "  -t  terminate instance(EC2 only)\n"
  printf "  -D  delete vm, works same with -t when ec2 instance\n"
  printf "  -n  [DISTRIBUSION.iso] create new instance from given image\n"
  printf "      for aws ec2, 'vm -n ec2 [--profile=YOURS]'\n"
  printf "        give '--AmazonLinux2' if you prefer that one'\n"
  printf "        give '--ami=ami-0c11b26d' if you prefer 2016.9\n"
  printf "          or any ami-id wanted to\n"
  printf "        latest version fo Amazon Linux(NOT 2) will be obtained as default\n"
  printf "  --hpv=[kind] specify hypervisor with option -n.\n"
  printf "      One of \"kvm\" \"vboxmanage\" \"vmrun\" acceptable\n"
  printf "  --name=[VMNAME_as_you_like] specify name of instance with option -n\n"
#  printf "     -e  [COMMAND ARGS1 2..] execute command on the guest\n"
#  printf "     -a  enable ssh & pubkey auto on the guest\n"
}

get_hpv() {
  which $1 > /dev/null && echo "new_instance_$1" && return 0
  local _default='qemu-system-x86_64'
  which "$_default" > /dev/null && echo "new_instance_$_default" && return 0
  return 1
}

get_host_ram_size() {
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


# obtain port number that is valid port number with '[random 3 digits]22' also currently unused
get_random_ssh_port() {

  which netstat > /dev/null || return 1

  while true; do
    readonly candidate=`awk -v min=100 -v max=655 'BEGIN{srand(); print int(min+rand()*(max-min+1))"22"}'`
    netstat -lat | grep $candidate && continue
    echo $candidate
    break
  done

  return 0

}

#https://fosspost.org/tutorials/use-qemu-test-operating-systems-distributions
new_instance_qemu-system-x86_64() {
  cd `mktemp -d`
  pwd
  local medium=`echo $* | tr ' ' '\n' | grep -e '.iso$' | tail -1`
  local memrate=8
  local hostramsize=`get_host_ram_size`
  local ramsize=`bc <<< "$hostramsize/$memrate"`
  local hostcpus=`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`
  local cpurate=4
  local cpus=`bc <<< "$hostcpus/$cpurate"+1`
  local info_file='kvm'

  #https://www.google.co.jp/search?num=24&safe=off&hl=en&q=kvm+qemu+fedora+29+slow&spell=1&sa=X&ved=0ahUKEwjsnLL08rneAhWiITQIHUlkDsEQBQgrKAA&biw=1918&bih=976
  #https://www.linuxquestions.org/questions/slackware-14/qemu-qxl-vga-not-available-4175632073/, https://forums.fedoraforum.org/showthread.php?306630-QEMU-KVM-intolerably-slow
  local vga=$(echo $* | grep -i -e 'fedora.*\.iso' > /dev/null && echo cirrus || echo qxl)

  echo "hpv kvm"          >> $info_file
  echo "cpus $cpus"       >> $info_file
  echo "ramsize $ramsize" >> $info_file
  echo "name $1"          >> $info_file
  echo "disk $1.img"      >> $info_file
  echo "vga $vga"         >> $info_file

  # format consiteration
  # https://qemu.weilnetz.de/doc/qemu-doc.html#disk_005fimages_005fformats
  # https://research.sakura.ad.jp/2010/03/23/kvm-diskperf1/
  qemu-img create -f vmdk $1.img 40G

  readonly random_ssh_port=`get_random_ssh_port`
  readonly kvm_net_hostfwd="user,hostfwd=tcp::$random_ssh_port-:22"

  echo "port $random_ssh_port"
  qemu-system-x86_64                 \
    -m $ramsize                      \
    -boot d -enable-kvm              \
    -smp $cpus                       \
    -net $kvm_net_hostfwd            \
    -net nic                         \
    -hda $1.img                      \
    -vga $vga                        \
    -name $1                         \
    -usb -usbdevice tablet           \
    -cdrom $medium
  exec $SHELL
  return 0
  # -net nic -net user              \
  # https://unix.stackexchange.com/questions/124681/how-to-ssh-from-host-to-guest-using-qemu
  # sample: with kali
  # guest$ systemstl restart ssh
  # host% ssh root@localhost -p10022
  # with fedora: systemctl start sshd.service https://docs.fedoraproject.org/ja-JP/Fedora/17/html/System_Administrators_Guide/s2-ssh-configuration-sshd.html
  #/etc/libvirt/hooks/qemu
  #run script in guest https://stackoverflow.com/questions/19118074/passing-script-to-vm-with-kvm
}

# https://nakkaya.com/2012/08/30/create-manage-virtualBox-vms-from-the-command-line/
# create new vm of VirtualBox with some spec
# usage:
#  new_instance_vboxmanage VMNAME PATH_TO_LIVECD_DVD.iso
# depends on:
#  vboxmanage
new_instance_vboxmanage() {
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
  local hostramsize=`get_host_ram_size`

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
  local medium=`echo $* | tr ' ' '\n' | grep -e '.iso$' | tail -1`
  VBoxManage storageattach "$uuid" --storagectl "ide" \
    --port 1 --device 0 --type dvddrive --medium "$medium"
  #vboxmanage modifyvm "$1" --macaddress1 XXXXXXXXXXXX
  #currdir=`pwd`
  cd $targetdir && vm
  echo $targetdir
  # http://d.hatena.ne.jp/kitokitoki/20120101/p2
  exec $SHELL
  return 0

}

# create new vm of VMWare player with some spec
# usage:
#  new_instance_vmrun VMNAME PATH_TO_LIVECD_DVD.iso
# depends on:
#  vmrun
#  repo in gist (means also network)
# Only support player, not for Fusion.
# Fusion7 can't handle the resource files created by newer version of Player which is 12
# And it requires to buy newer one
# Why do I have to do something special further for "Fusion" so foolishly
new_instance_vmrun() {
  if [ "$(uname)" = 'Darwin' ]; then
    local HOST="fusion"
  else
    local HOST="player"
  fi

  # Name of predefined resource files
  local boilerplate_name="vmx_boilerplate"
  local srcname="struct_vmx"

  # get predefined resource files
  local getsrc() {
    local src="/var/tmp/$boilerplate_name"
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
    local medium=`echo $* | tr ' ' '\n' | grep -e '.iso$' | tail -1`
    sed -i 's|/dev/null/dummy.iso|'$medium'|g' $vmx # ofcourse it must be replaced with proper name..
    echo $vmx
  }

  local VMX=`getinstance $*`
  vmrun -T $HOST start $VMX
  #echo $instancedir
  # http://d.hatena.ne.jp/kitokitoki/20120101/p2
  cd $instancedir
  #echo "vmrun -T $HOST -gu USER -gp PASSWORD runProgramInGuest ./`ls | grep .vmx$` CMMAND"
  exec $SHELL
  return 0
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

aws_profile=`echo $* | tr ' ' '\n' | grep -e '--profile=' | tr '=' ' '`
aws_retry_sec=3

list_running_instances() {
  echo "JSON.parse( '"`aws ec2 describe-instances --filters='Name=instance-state-name,Values=running'`"' ).Reservations.forEach( ( r ) => { r.Instances.forEach( ( i ) => { console.log( i.KeyName ); } ) } );" | node -
}

delete_instance() {
  aws $aws_profile ec2 terminate-instances --instance-ids `cat instance.id`

  while true
  do
    #[ $(aws $aws_profile ec2 delete-security-group --group-name `cat vmname`) > /dev/null ] && break
    aws $aws_profile ec2 delete-security-group --group-name `cat vmname` 2> /dev/null
    [ "`aws ec2 describe-security-groups | grep $(cat vmname) 2> /dev/null`" ] || break
    sleep $aws_retry_sec
  done

  aws ec2 $aws_profile delete-key-pair --key-name  `cat vmname`
  list_running_instances
}

ip_permissions() {
  echo '[{"IpProtocol": "tcp", "FromPort": '$1', "ToPort": '$1', "IpRanges": [{"CidrIp": "'`curl -s http://checkip.amazonaws.com/`'/32", "Description": "ask user"}]}]'
}

get_security_id() {
  local id=$(echo "console.log( JSON.parse( process.argv[ 2 ] ).GroupId );" | node - "`cat securitygroup`")
  echo $id
}

auth() {
  aws $aws_profile ec2                        \
  authorize-security-group-ingress            \
  --group-id `get_security_id`                \
  --ip-permissions "`ip_permissions $1`"
}

# to create instance from 2016.9,
# vm -n ec2 --ami=ami-0c11b26d
new_instance_aws() {
  cd `mktemp -d`
  pwd
  # if ec2 was unreachable, return as an error
  echo $1 > vmname
  echo $1
  aws $aws_profile ec2 describe-instances > /dev/null || return 1
  aws $aws_profile ec2 create-security-group \
  --description "dedicated for instance $1. ask the user who create this, he may not need this anymore" \
  --group-name "$1" \
  > ./securitygroup

  auth 80
  auth 443
  auth 22

  #aws ec2 $aws_profile describe-security-groups --group-names $1
  #local ami=`aws ec2 $aws_profile describe-images --owners amazon --filters 'Name=name,Values=amzn-ami-hvm-????.??.?.x86_64-gp2' 'Name=state,Values=available' | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId'`
  # https://gist.github.com/nikolay/12f4ca2a592bbfa0df57c3bbccb92f0f

  local readonly amazon_linux_version=`echo $* | tr ' ' '\n' | egrep '\-\-AmazonLinux' | sed 's/[^0-9]//g' | tr -d '\n'`
  if [ `echo $* | grep '\-\-ami' > /dev/null; echo $?` = 0 ]; then
    local readonly ami=`echo $* | tr ' ' '\n' | grep '\-\-ami' | sed -e 's/--ami=//'`
  else
    local readonly ami=`aws ec2 describe-images                       \
      --owners amazon                                                 \
      --filters                                                       \
        'Name=name,Values=amzn'$amazon_linux_version'-ami-hvm-?*-x86_64-gp2' \
        'Name=state,Values=available'                                 \
        'Name=architecture,Values=x86_64'                             \
        'Name=virtualization-type,Values=hvm'                         \
        'Name=root-device-type,Values=ebs'                            \
      --query 'sort_by(Images, &CreationDate)[-1].ImageId' | tr -d '"' \
    `
  fi
  # for amazon linux 2
  # https://aws.amazon.com/amazon-linux-2/release-notes
  aws ec2 $aws_profile create-key-pair --key-name $1 > keypair.json

  echo "console.log( JSON.parse( process.argv[ 2 ] ).KeyMaterial );" |
  node - "`cat keypair.json`" > key_rsa
  chmod 600 key_rsa

  aws ec2 run-instances                      \
  --image-id $ami                            \
  --count 1                                  \
  --instance-type t3.nano                    \
  --credit-specification CpuCredits=standard \
  --key-name $1                              \
  --security-groups $1                       \
  > ec2.instance

  cat ec2.instance | grep InstanceId | sed -e 's/"InstanceId"://' | sed -e 's/[", ]//g' > instance.id
  #aws ec2 $aws_profile describe-instances --query "Reservations[].Instances[].[InstanceId,PublicIpAddress]" --instance-ids=`cat instance.id`
  #aws ec2 $aws_profile describe-instances --query "Reservations[].Instances[].[InstanceId,PublicIpAddress]" --instance-ids=`cat instance.id` | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sed 's/[" ]//g' > ipv4

  #https://stackoverflow.com/questions/35772757/how-to-rename-ec2-instance-name
  aws $aws_profile ec2 create-tags --resources `cat instance.id` --tag "Key=Name,Value=$1"

  #echo 'trying to connect..' >&2
  while true
  do
    aws ec2 $aws_profile describe-instances --query "Reservations[].Instances[].[InstanceId,PublicIpAddress]" --instance-ids=`cat instance.id` | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sed 's/[" ]//g' > ipv4
    if [ ! `cat ipv4  | egrep '([0-9]+\.){3}[0-9]+$'` ]; then
      echo 'no ip address obtained. trying again..'
      sleep $aws_retry_sec
      continue
    fi
    ssh ec2-user@`cat ipv4` -o 'StrictHostKeyChecking no' -i key_rsa 'uname' > /dev/null 2>&1
    [ "$?" = 0 ] && break
    sleep $aws_retry_sec
    #echo retrying.. >&2
  done

  #echo "\"ssh ec2-user@`cat ipv4` -o 'StrictHostKeyChecking no' -i key_rsa\" to ssh the one"
  #aws ec2 $aws_profile describe-key-pairs
  #delete_instance $1
  ssh ec2-user@`cat ipv4` -o 'StrictHostKeyChecking no' -i key_rsa
  exec $SHELL
}

newvm() {
  local arghpv=`get_arghpv $* | awk '{print $1}'`
  [ -z "`get_hpv $arghpv 2> /dev/null`" ] && echo "no hypervisor found" >&2 && return 1
  local vname=$(get_vmname `get_argvname $*`)
  if [ "`echo $* | grep 'ec2' > /dev/null; echo $?`" = 0 ]; then
    local new_instance_cmd='new_instance_aws'
  else
    local new_instance_cmd="`get_hpv $arghpv`"
  fi
  $new_instance_cmd "$vname" "$*"
}

# start Virtual Machine
vm() {


  VMX=`find . -maxdepth 1 -name *.vmx` 2> /dev/null

  if [ -n "$VMX" ]; then

    if [ "$(uname)" = 'Darwin' ]; then
      HOST="fusion"
    else
      HOST="player"
    fi

    # http://www.japan-secure.com/entry/how_to_add_a_snapshot_function_in_vmware_workstation_player.html
    local isAlreadyEnabled=`grep -E '^scsi0:0.mode = "independent-nonpersistent' $VMX`
    local isMutable=$(echo $* | grep -e '-m')

    while getopts iskd:DlrSt:Rm OPT; do
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
        r) echo restart Virtual Machine..
          vmrun -T $HOST reset $VMX hard
          return 0
          ;;
        s) echo halt Virtual Machine..
          vmrun -T $HOST stop $VMX soft
          return 0
          ;;
        k) echo 'kill Virtual Machine..'
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
        m) ;;
        *) ;;
      esac
    done

    if [ -n "$isMutable" ]; then
      sed -i '/scsi0:0.mode = \"independent-nonpersistent\"/d' $VMX
      vmrun -T $HOST start $VMX
      return 0
    elif [ -n "$isAlreadyEnabled" ]; then
      vmrun -T $HOST start $VMX
      return 0
    else
      sed -ie "/^scsi0:0\.fileName/a scsi0:0.mode = \"independent-nonpersistent\"" $VMX
      vmrun -T $HOST start $VMX
      return 0
    fi
    return 0
  fi

  VBOX=`find . -maxdepth 1 -name *.vbox` 2> /dev/null

  if [ -n "$VBOX" ]; then
    VBOXPATH=`pwd`/`echo $VBOX | sed -e 's/^\.\///'`

    while getopts iskrRDe: OPT
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
        e)
           #vboxmanage guestcontrol "$VBOXPATH" run --exe "/bin/bash" --username mint --password "" --wait-stdout --wait-stderr -- $*
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

  ec2=`find . -maxdepth 1 -name ec2.instance` 2> /dev/null

  if [ -n "$ec2" ]; then
    while getopts iskrDte: OPT
    do
      case $OPT in
#        s) echo halt Virtual Machine..
#           return 0
#           ;;
#        k) echo kill Virtual Machine..
#           return 0
#           ;;
#        r) echo restart Virtual Machine..
#           return 0
#           ;;
        i)  aws $aws_profile ec2 describe-instances --instance-ids `cat instance.id`
           echo 'all running instances:'
           list_running_instances
           return 0
           ;;
        D) delete_instance $*
           return 0
           ;;
        t) delete_instance $*
           return 0
           ;;
        *) ;;
      esac
    done
  fi
  local kvm=`find . -maxdepth 1 -name kvm` 2> /dev/null

  if [ -n "$kvm" ]; then

    local temporarily='-snapshot'

    while getopts iskrDm OPT
    do
      case $OPT in
        s) echo halt Virtual Machine..
           return 0
           ;;
        k) echo 'kill Virtual Machine..'
           return 0
           ;;
        r) echo restart Virtual Machine..
           return 0
           ;;
        i)
           return 0
           ;;
        D) rm -i ./*
           return 0
           ;;
        m) temporarily=''
          ;;
        *)
          ;;
      esac
    done

    readonly random_ssh_port=`get_random_ssh_port`
    readonly kvm_net_hostfwd="user,hostfwd=tcp::$random_ssh_port-:22"

    echo "port $random_ssh_port"
    qemu-system-x86_64                                    \
      -m `cat kvm | grep -e 'ramsize' | awk '{print $2}'` \
      -boot c -enable-kvm                                 \
      -smp `cat kvm | grep -e 'cpus' | awk '{print $2}'`  \
      -net $kvm_net_hostfwd                               \
      -net nic                                            \
      -hda `cat kvm | grep -e 'disk' | awk '{print $2}'`  \
      -vga `cat kvm | grep -e 'vga' | awk '{print $2}'`   \
      -name `cat kvm | grep -e 'name' | awk '{print $2}'` \
      -usb -usbdevice tablet                              \
      -soundhw all                                        \
      $temporarily

      # http://blog.livedoor.jp/les_paul_sp/archives/694273.html
      #https://wiki.qemu.org/Documentation/CreateSnapshot#Temporary_snapshots
      # about bridge networking
      # https://www.google.com/search?biw=2343&bih=1147&ei=hbcYXOHXF4_m8wWA9Z3YBw&q=bridge-utils+kvm+qemu&oq=bridge-utils+kvm+qemu&gs_l=psy-ab.3..0i8i30.9726.12636..12837...1.0..0.124.923.8j2......0....1..gws-wiz.......0j0i71j0i30j0i19j0i30i19j0i10i30i19j0i8i30i19j0i4i30i19j0i8i4i30i19j0i5i30i19j33i21.Ehq6Z87jTng
      # https://www.nexia.jp/server/1612/
      # http://www.uetyi.com/server-const/entry-1284.html
      #https://wiki.archlinux.jp/index.php/QEMU#QEMU_.E3.81.AE_Tap_.E3.83.8D.E3.83.83.E3.83.88.E3.83.AF.E3.83.BC.E3.82.AF
      # https://help.ubuntu.com/community/KVM/Networking
  fi
}

while getopts hn: 2> /dev/null OPT
do
  case $OPT in
    h)  help
        return 0
        ;;
    n)  newvm $*
        exit 0
        ;;
  esac
done

vm $*


