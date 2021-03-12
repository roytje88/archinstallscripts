#!/bin/bash

        hdds=()
        for hdd in $(lsblk -o KNAME,TYPE |grep part|cut -d' ' -f1); do
            hdds=("${hdds[@]} "${hdd})
        done

        arr=""
        for hdd in $hdds; do
            arr="$arr $hdd \"$(lsblk -o SIZE,KNAME|grep $hdd|xargs|cut -d' ' -f1)\" off "
	echo $arr
        done


arraytje=($arr)

for i in ${arraytje[@]}; do
 	echo $i
done
