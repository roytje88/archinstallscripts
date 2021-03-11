#!/bin/bash

function installifnotinstalled () {
    if pacman -Qs $1 > /dev/null ; then
        echo "$1 already installed."
    else
        pacman -S $1 --noconfirm
    fi
}

DEs=("gnome GnomeDesktop" "lxde LXDE" "mate MATE")

options=""
for de in "${DEs[@]}"; do
    options="$options $de off "
done

dearr=($options)
cmd=(dialog --checklist "Select which Desktop environment(s) should be installed" 22 76 16)
destoinstall=$("${cmd[@]}" "${dearr[@]}" 2>&1 >/dev/tty)

for choice in $destoinstall; do
    installifnotinstalled $choice
done
