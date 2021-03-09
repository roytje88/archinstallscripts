#!/bin/bash

mapfile -t -n 0 myArray < /etc/locale.gen

# arr=()
# while IFS= read -r line || [[ "$line" ]]; do
#   arr+=("$line")
# done < /etc/locale.gen

printf '%s\n' "${myArray[@]}"
# echo $myArray