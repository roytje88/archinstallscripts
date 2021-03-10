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

if [ ! $? -eq 255 ]; do
    for choice in $harddisks; do
        addfixeddisk "$choice"
    done
else
    echo "Canceled!"
done
