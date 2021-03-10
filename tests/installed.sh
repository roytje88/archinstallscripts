#!/bin/bash


function installifnotinstalledwithpacker () {
    if pacman -Qs $1 > /dev/null ; then
        echo "$1 already installed."
    else
        username=$(dialog --inputbox "Enter user to install $1" 10 30 --output-fd 1)
        runuser -l $username -c "packer -S $1 --noconfirm"
    fi
}


installifnotinstalledwithpacker mesa-git