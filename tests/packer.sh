#!/bin/bash


ips=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
arr=""
for ip in $ips; do
#     echo $ip
    arr="$arr $ip IP off "
done

tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15


dialog --backtitle "Test" \
    --radiolist "test" 0 0 5 \
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


# echo $arr