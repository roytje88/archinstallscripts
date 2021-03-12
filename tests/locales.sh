#!/bin/bash

# IFS=$'\n' read -d '' -r -a lines < /etc/locale.gen


# arr=()
# while IFS= read -r line || [[ "$line" ]]; do
#   arr+=("$line")
# done < /etc/locale.gen

# for i in ${lines[@]}; do
#     echo $i
#     echo newline
# done


#printf '%s\n' "${myArray[@]}"
# echo $myArray




file="/etc/locale.gen"
lines=`cat $file`
for line in $lines; do
        echo "$line"
done