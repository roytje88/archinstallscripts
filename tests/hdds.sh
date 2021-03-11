#!/bin/bash

function addfixeddisk() {
mountpt=$(dialog --title "Harddisks" --backtitle "Set fixed mountpoints for harddisks" --inputbox "Enter the desired mountpoint for $1, "$(lsblk -o SIZE,KNAME|grep $1|xargs|cut -d' ' -f1)" (i.e. /media/harddisk)." 10 30 --output-fd 1)

echo "UUID=\"$(blkid -o value -s UUID /dev/$1)\" $mountpt ext4 defaults 0 0" >> /etc/fstab
}

hdds=()
for hdd in $(lsblk -o KNAME,TYPE |grep part|cut -d' ' -f1); do
    hdds=("${hdds[@]} "${hdd})
done

arr=""
for hdd in $hdds; do
    arr="$arr $hdd \"$(lsblk -o SIZE,KNAME|grep $hdd|xargs|cut -d' ' -f1)\" off "
done

hddarr=($arr)

dialogcmd=(dialog --checklist "Select for which harddisk(s) a fixed mountpoint should be created." 22 76 16)

harddisks=$("${dialogcmd[@]}" "${hddarr[@]}" 2>&1 >/dev/tty)


for choice in $harddisks; do
    addfixeddisk "$choice"
done


ips=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
arr=""
for ip in $ips; do
    arr="$arr $ip IP off "
done

tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15


dialog --backtitle "Test" \
    --radiolist "Select IP address on which to cast the NFS server" 0 0 5 \
    $arr 2> $tempfile

retval=$?

choice=`cat $tempfile`
case $retval in
  0)
    mkdir -p $share
    echo "$actualfolder $share none bind 0 0" >> /etc/fstab
    echo "$share $choice/24(rw,no_subtree_check,nohide,sync,no_root_squash,insecure,no_auth_nlm)" >> /etc/exports
    exportfs -rav
    ;;
  1)
    echo "Cancel pressed.";;
  255)
    echo "ESC pressed.";;
esac  
;;