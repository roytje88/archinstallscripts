#!/bin/bash

# function addfixeddisk() {
# mountpt=$(dialog --title "Harddisks" --backtitle "Set fixed mountpoints for harddisks" --inputbox "Enter the desired mountpoint for $1, "$(lsblk -o SIZE,KNAME|grep $1|xargs|cut -d' ' -f1)" (i.e. /media/harddisk)." 10 30 --output-fd 1)

# echo "UUID=\"$(blkid -o value -s UUID /dev/$1)\" $mountpt ext4 defaults 0 0" >> /etc/fstab
# }

tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

hdds=()
for hdd in $(lsblk -o KNAME,TYPE |grep disk|cut -d' ' -f1); do
    hdds=("${hdds[@]} "${hdd})
done

arr=""
for hdd in $hdds; do
    arr="$arr $hdd \"$(lsblk -o SIZE,KNAME|grep $hdd|xargs|cut -d' ' -f1)\" off "
done

dialog --radiolist "Select the SD card" 0 0 5 \
    $arr 2> $tempfile

retval=$?

choice=`cat $tempfile`
case $retval in
  0)
    echo $choice
    ;;
  1)
    echo "Cancel pressed.";;
  255)
    echo "ESC pressed.";;
esac  

