#!/bin/zsh

alias aws='aws2'

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
  printf "  -e  COMMAND execute COMMAND via ssh when a connection was established\n"
  #https://serverfault.com/questions/336298/can-i-change-a-user-password-in-linux-from-the-command-line-with-no-interactivit
#  printf "     -e  [COMMAND ARGS1 2..] execute command on the guest\n"
#  printf "     -a  enable ssh & pubkey auto on the guest\n"
}

localisosum="/tmp/localisosum"
_transmission_cli() {
  rm -rf ~/.config/transmission/torrents
  rm -f $localisosum
  local args=`cat`
  local isotorrent=`echo $args | awk '{print $1}'`
  local sha256sum=`echo $args | awk '{print $2}'`
  (transmission-cli $isotorrent) &
  echo "Awaiting target has completely downloaded" >&2
  while true; do
    cd ~/Downloads
    sha256sum **/*${1}*.iso | grep ${sha256sum} > $localisosum && echo "Downloaded $isotorrent" >&2 && echo 'done' && break
    sleep 4
  done
  ps aux | grep -iE '(torrent|transmission\-cli)' | grep -i "${1}" | awk '{print $2}' | xargs kill
  return 0
}

download_latest_kali(){
  curl https://www.kali.org/get-kali/  | grep -iEoh '((SHA256sum.*)).*http.*live.*amd64.*\.iso"?' | sed -e 's/<\/[[:alnum:]]\+>/ /g' | sed -e 's/<a[[:blank:]]\?href=//' | tr -d '"' | grep -vi 'everything' | sort -u | head -n1 | awk '{print $3".torrent",$2}' | _transmission_cli kali
}

#https://ftp.yz.yamagata-u.ac.jp/pub/linux/fedora-projects/fedora/linux/releases/38/Spins/x86_64/iso/
#https://torrent.fedoraproject.org/
download_latest_fedora(){
  local isotorrent=`curl https://torrent.fedoraproject.org/ | grep -iEoh 'https:.*xfce.*\.torrent' | awk 'BEGIN{FS="[>\"]"} {print $1}' | sort -u | tail -n1`
  echo "$isotorrent"
  local torrentversion=`echo "$isotorrent" | grep -iEoh '[0-9]+\.torrent' | grep -Eoh '[0-9]+'`
  local checksumfiledir="https://ftp.yz.yamagata-u.ac.jp/pub/linux/fedora-projects/fedora/linux/releases/${torrentversion}/Spins/x86_64/iso/"
  local checksumfile=`curl $checksumfiledir | grep -iEoh 'Fedora-.*CHECKSUM' | awk 'BEGIN{FS="[>\"]"} {print $1}' | head -n1`
  local checksumfileurl="${checksumfiledir}${checksumfile}"
  echo $checksumfileurl
  local sha256sum=`curl $checksumfileurl | grep -iE 'SHA256.*xfce' | awk '{print $NF}'`
  echo $sha256sum
  echo "$isotorrent $sha256sum"
  echo "$isotorrent $sha256sum" | _transmission_cli Fedora
}

download_latest_debian(){
  #transmission-cli https://cdimage.debian.org/debian-cd/current/amd64/bt-dvd/debian-12.1.0-amd64-DVD-1.iso.torrent
}

download_latest_lmde(){
  local resources=`mktemp`
  local editionphp=`curl https://linuxmint.com/download_lmde.php | grep -iEoh 'edition\.php\?id=[a-zA-Z0-9]*' | sort -u | head -n1`
  echo $editionphp
  curl "https://linuxmint.com/${editionphp}" | grep -iEoh 'https:.*(.*lmde.*64bit.*\.torrent|sha256sum\.txt)' | awk 'BEGIN{FS=">"} {print $1}' | sort | tr -d '"' | grep -vE '\.gpg$' > $resources
  local isotorrent=`cat $resources | grep '.torrent'`
  local sha256sumtxt=`cat $resources | grep 'sha256sum.txt'`
  echo $isotorrent
  echo $sha256sumtxt
  local iso=`echo $isotorrent | grep -iEoh 'lmde.*\.iso'`
  echo $iso
  local sha256sum=`curl $sha256sumtxt | grep $iso | awk '{print $1}'`
  echo $sha256sum
  echo "$isotorrent $sha256sum" | _transmission_cli lmde
  rm -f $resources
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

function hostfwdtrans () { cat  | awk '{print ",hostfwd=tcp::"$1"-:"$1}' | tr -d '\n' }

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
  qemu-img create -f vmdk $1.img 58G

  readonly random_ssh_port=`get_random_ssh_port`
  readonly kvm_net_hostfwd_ssh="user,hostfwd=tcp::$random_ssh_port-:22"

  #echo "port $random_ssh_port"
  printf 'on fedora: sudo passwd root; su; echo root:pass | chpasswd && service sshd start && systemctl enable sshd\n'
  printf 'on kali: systemctl start ssh.service\n'
  #https://www.liquidweb.com/kb/enable-root-login-via-ssh/

  echo medium=$medium
  qemu-system-x86_64                 \
    -m $ramsize                      \
    -boot d -enable-kvm              \
    -smp $cpus                       \
    -net $kvm_net_hostfwd_ssh        \
    -net nic                         \
    -vga $vga                        \
    -name $1                         \
    -cdrom "$medium"                   \
    $1.img                      &
#    -usb -usbdevice tablet           \
#    -serial telnet:localhost:4321,server,nowait \
#    -monitor tcp:127.0.0.1:55555,server,nowait;
  guestuser="`whoami`"
  #if echo $medium | grep -i 'mint'; then
    echo "ssh -oStrictHostKeyChecking=no $guestuser@localhost -p $random_ssh_port" > ./ssh.sh
    chmod +x ./ssh.sh
    printf "issue command shown below on the guest VM\n"
    echo "curl https://raw.githubusercontent.com/o2346/pde/develop/mint/bootstrap.sh | bash -s"
    seq 32 | while read $wait; do
      ssh -oStrictHostKeyChecking=no $guestuser@localhost -p $random_ssh_port : && break
      sleep 4
    done
    ssh -oStrictHostKeyChecking=no $guestuser@localhost -p $random_ssh_port
  #fi

    #-chardev socket,id=monitor,path=/tmp/monitor.sock,server,nowait \
    #-monitor chardev:monitor \
    #-chardev socket,id=serial0,path=/tmp/console.sock,server,nowait \
    #-serial chardev:serial0
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
  #https://unix.stackexchange.com/a/426951
  ##https://sononi.com/memo/2019/06/21/qemumonitor/
  #https://www.linux-kvm.org/page/Simple_shell_script_to_manage_your_virtual_machine_with_bridged_networking
  #https://stackoverflow.com/a/19352056
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

readonly aws_argn=`seq $# | while read argn; do
  echo $* | tr ' ' '\n' | awk '{if(NR=='$argn') print $0}' | grep 'ec2' > /dev/null && echo $argn
done`
readonly aws_option=${@:$((aws_argn+2)):$#}
#printf $aws_option #should be "--region ap-northeast-1" in "vm -n ec2 --region ap-northeast-1" for example
#https://stackoverflow.com/questions/1497811/how-to-get-the-nth-positional-argument-in-bash

aws_retry_sec=5

delete_instance() {
  local readonly instance_ids=$(aws ec2 describe-instances `echo "$aws_option"` --query 'Reservations[].Instances[?contains(KeyName,`'$1'`)].{InstanceId:InstanceId}' --output text | awk 'BEGIN{ORS=" "} {print $0}' | sed -e 's/ $//g')
  aws ec2 `echo "$aws_option"` describe-instances --instance-ids $instance_ids --output text --query 'Reservations[].Instances[?Stane.name!=`Terminated`].{KeyName:KeyName}' > /dev/null
  if [ "$?" = 0 ]; then
    aws ec2 `echo "$aws_option"` terminate-instances --instance-ids $instance_ids
  fi

  local maxtry=20
  sleep 16 # It will anyway not succeed within a moment
  # try deletion or give up
  seq $maxtry | while read attemption; do
    echo "Security Group deletion attemption number $attemption of $maxtry" >&2
    aws ec2 `echo "$aws_option"` describe-security-groups --group-names $1 > /dev/null || break
    aws ec2 `echo "$aws_option"` delete-security-group --group-name $1 && echo "Successfully deleted security group $1" && break
    [ "$attemption" = "$maxtry" ] && echo "Warning: Gave up deletion of security group $1" && break
    printf "All right, Let's try again in few seconds.. " >&2
    sleep $aws_retry_sec
  done

  aws ec2 `echo "$aws_option"` delete-key-pair --key-name $1
  aws ec2 `echo "$aws_option"` describe-instances \
    --output text                                 \
    --query 'Reservations[].Instances[?KeyName==`'$1'` && State==`Terminated`].{KeyName:KeyName,State:State}'
  #https://gist.github.com/jpbarto/38ce994ced3f85128243d50fc11b7b0b
}

ip_permissions() {
  echo '[{"IpProtocol": "tcp", "FromPort": '$1', "ToPort": '$1', "IpRanges": [{"CidrIp": "'`curl -s http://checkip.amazonaws.com/`'/32", "Description": "ask user"}]}]'
}

get_security_id() {
  local id=$(echo "console.log( JSON.parse( process.argv[ 2 ] ).GroupId );" | node - "`cat securitygroup`")
  echo $id
}

auth() {
  aws ec2 `echo "$aws_option"`  authorize-security-group-ingress  \
  --group-id `get_security_id`                                    \
  --ip-permissions "`ip_permissions $1`"
}

# no use for now. you need permisson to mamipulate iam role, policy
# also I don't want custom role created on this context to be remaind, Manual deletion unavoidable
# SSO_reserved role for lambda func was rejected by aws like below
#
#% vm -n ec2
#arn:aws:iam::981231879765:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdvancedPowerUser_7b08fb5518d2e5ce
#An error occurred (InvalidParameterValueException) when calling the CreateFunction operation: The role defined for the function cannot be assumed by Lambda.
create_automatic_deletion_function() {
  local readonly this_script_dir=`which vm | awk '{print $NF}' | xargs dirname`
  zip -rq ./self_destruction.zip $this_script_dir/self_destruction.py
  ls
  local readonly current_role_arn=$(aws sts get-caller-identity --query 'Arn' --output text | grep -Eo 'AWSReservedSSO_[a-zA-Z]+_' | xargs -I_ROLENAME_ aws iam list-roles --query 'Roles[?contains(Arn,`_ROLENAME_`)].{Arn:Arn}' --output text)
  echo $current_role_arn
  aws lambda create-function                                          \
    `echo $aws_option`                                                \
    --function-name delete_ec2_secg_keys_$1                           \
    --runtime  python3.8                                               \
    --role $current_role_arn                                          \
    --handler index.handler                                           \
    --zip-file fileb://./self_destruction.zip                                 \
    --timeout 30                                                      \
    --description 'self_descruction test'
#	@aws lambda add-permission               \
#	--function-name $(func_name)                           \
#	--statement-id "s3-put-event"                          \
#	--action "lambda:InvokeFunction"                       \
#	--principal "s3.amazonaws.com"                         \
#	--source-arn "arn:aws:s3:::$(target_bucket)"
#  echo $this_script_dir $1
  #
}

# to create instance from 2016.9,
# vm -n ec2 --ami=ami-0c11b26d
# For future, How about counterpart of Lambda & CloudFormation ?
new_instance_aws() {
  local readonly workdir="`mktemp -du`_$1"
  mkdir $workdir
  cd $workdir
  pwd
  echo $1 > vmname

  # if ec2 was unreachable, return as an error
  aws ec2 `echo "$aws_option"` describe-instances > /dev/null || return 1

  aws ec2 `echo "$aws_option"` create-security-group \
  --description "dedicated for instance $1. ask the user who create this, he may not need this anymore" \
  --group-name "$1" \
  > ./securitygroup

  auth 80
  auth 443
  auth 22

  local readonly ami=`aws ssm $(echo "$aws_option") get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --query 'Parameters[].Value' --output text`
  # https://gist.github.com/nikolay/12f4ca2a592bbfa0df57c3bbccb92f0f
  # https://aws.amazon.com/amazon-linux-2/release-notes

  aws ec2 `echo "$aws_option"` create-key-pair --key-name $1 > keypair.json
  echo "console.log( JSON.parse( process.argv[ 2 ] ).KeyMaterial );" |
  node - "`cat keypair.json`" > key_rsa
  chmod 600 key_rsa

  echo '[{"ResourceType": "volume", "Tags": [{"Key":"Name","Value":"'$1'"}]},{"ResourceType": "instance", "Tags": [{"Key":"Name","Value":"'$1'"}]}]' |
    python3 -m json.tool > ./tag_specifications

  aws ec2 run-instances                                                      \
    `echo "$aws_option"`                                                     \
    --image-id $ami                                                          \
    --count 1                                                                \
    --instance-type t3.nano                                                  \
    --credit-specification CpuCredits=standard                               \
    --key-name $1                                                            \
    --tag-specifications  "`cat ./tag_specifications`"                       \
    --security-groups $1                                                     \
    --instance-initiated-shutdown-behavior terminate                         \
  > ec2.instance

  cat ec2.instance | grep InstanceId | sed -e 's/"InstanceId"://' | sed -e 's/[", ]//g' > instance.id

  # confirm ssh connection
  while true; do
    aws ec2 `echo "$aws_option"` describe-instances --instance-ids=`cat instance.id` --query "Reservations[].Instances[].{PublicIpAddress:PublicIpAddress}" --output text > ipv4
    if [ ! `cat ipv4  | egrep '([0-9]+\.){3}[0-9]+$'` ]; then
      echo 'no ip address obtained. trying again..'
      sleep $aws_retry_sec
      continue
    fi
    ssh ec2-user@`cat ipv4` -o 'StrictHostKeyChecking no' \
      -i key_rsa 'uname' > /dev/null 2>&1                 && break
    sleep $aws_retry_sec
  done

  printf "#!/bin/bash\nssh ec2-user@`cat ipv4` -o 'StrictHostKeyChecking no' -i `pwd`/key_rsa" > ./ssh.sh
  chmod +x ./*.sh
  trap "delete_instance $1 &" ERR EXIT # it should be more persistent like suffered under nw problems
  ssh ec2-user@`cat ipv4` -o 'StrictHostKeyChecking no' -o 'ServerAliveInterval 240' -o 'ServerAliveCountMax 200' -i key_rsa
  #https://serverfault.com/questions/538897/serveralivecountmax-in-ssh
  #https://www.a2hosting.com/kb/getting-started-guide/accessing-your-account/keeping-ssh-connections-alive
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
_vm() {

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
          if which vmrun; then
            vmrun -T $HOST stop $VMX hard
          elif which vmplayer; then
            #killall vmplayer
            ps aux | grep -iE '(vmplayer|vmware)' | awk '{print $2}' | xargs sudo kill
            #ps aux | grep -i vmware | awk '{print $2}' | xargs kill
            #        grep "`ls *.vmx`"
            #Since it likely causes breaking host os at shutdown or closing in normal way. Host os completely freezes right after execution of such way
            #Similer error messages are shown 2021/01/16
            #https://askubuntu.com/questions/1214111/vmplayer-closes-on-start-of-vm
          else
            echo "[ERROR] neither commands for VMWare found.abort" >&2
            return 1
          fi
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

    if which vmrun; then
      vmware="vmrun -T $HOST start"
    elif which vmplayer; then
      vmware="vmplayer"
    else
      echo "[ERROR] neither commands for VMWare found.abort" >&2
      return 1
    fi
    #ls /usr/lib/vmware/bin/
    #ls -al /usr/bin/*vm*

    if [ -n "$isMutable" ]; then
      sed -i '/scsi0:0.mode = \"independent-nonpersistent\"/d' $VMX
      ($vmware $VMX) &
    elif [ -n "$isAlreadyEnabled" ]; then
      ($vmware $VMX) &
    else
      sed -ie "/^scsi0:0\.fileName/a scsi0:0.mode = \"independent-nonpersistent\"" $VMX
      ($vmware $VMX) &
    fi
    return $?
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
        i)  aws ec2 $aws_option describe-instances --instance-ids `cat instance.id`
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

    readonly default_allowed_ports='80\n443\n18383'
    readonly random_ssh_port=`get_random_ssh_port 2>/dev/null`
    #https://serverfault.com/a/704300
    readonly kvm_net_hostfwd_ssh="user,hostfwd=tcp::$random_ssh_port-:22"
    sudo firewall-cmd --zone=public --add-port=$random_ssh_port/tcp
    readonly kvm_net_hostfwd_default="`printf "$default_allowed_ports" | hostfwdtrans`"
    printf "$default_allowed_ports" | xargs -I{} sudo firewall-cmd --zone=public --add-port={}/tcp
    if [ -f "./hostfwd" ]; then
      kvm_net_hostfwd_miscs="`cat hostfwd | hostfwdtrans`"
      cat hostfwd | while read port; do
        sudo firewall-cmd --zone=public --add-port=${port}/tcp
      done
      sudo firewall-cmd --zone=public --list-ports
    else
      kvm_net_hostfwd_miscs=''
    fi
    readonly kvm_net_hostfwd="$kvm_net_hostfwd_ssh$kvm_net_hostfwd_default$kvm_net_hostfwd_miscs"
    echo "$kvm_net_hostfwd" >&2

    echo "port $random_ssh_port"
    qemu-system-x86_64                                    \
      -m `cat kvm | grep -e 'ramsize' | awk '{print $2}'` \
      -boot c -enable-kvm                                 \
      -smp `cat kvm | grep -e 'cpus' | awk '{print $2}'`  \
      -net $kvm_net_hostfwd                               \
      -net nic                                            \
      -vga `cat kvm | grep -e 'vga' | awk '{print $2}'`   \
      -name `cat kvm | grep -e 'name' | awk '{print $2}'` \
      $temporarily \
      "`cat kvm | grep -e 'disk' | awk '{print $2}'`"  &
#      -usb -usbdevice tablet                              \
      #-soundhw all                                        \

      echo $! > pid
      echo $random_ssh_port > port
      guestuser="`whoami`"
      printf "#!/bin/bash\nssh -oStrictHostKeyChecking=no $guestuser@localhost -p $random_ssh_port" > ./ssh.sh
      #printf '#!/bin/bash\n ssh -o "ConnectTimeout=10" -o "StrictHostKeyChecking no" -p '$random_ssh_port' -i ./id_rsa localhost $*'  > ./ssh
      chmod +x ./ssh.sh

      #if echo 'mint' | grep -i 'mint'; then
        echo "ssh -oStrictHostKeyChecking=no $guestuser@localhost -p $random_ssh_port" > ./ssh.sh
        chmod +x ./ssh.sh
        printf "issue command shown below on the guest VM\n"
        echo "curl https://raw.githubusercontent.com/o2346/pde/develop/mint/bootstrap.sh | bash -s"
        seq 32 | while read $wait; do
          ssh -oStrictHostKeyChecking=no $guestuser@localhost -p $random_ssh_port : && break
          sleep 4
        done
        ssh -oStrictHostKeyChecking=no $guestuser@localhost -p $random_ssh_port
      #fi
      #if [ -f "./id_rsa" ]; then
      #  while true; do
      #    ssh                             \
      #      -o "ConnectTimeout=10"        \
      #      -o "StrictHostKeyChecking no" \
      #      -p $random_ssh_port           \
      #      -i ./id_rsa localhost && break
      #    sleep 4
      #  done
      #fi
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

_vm $*

