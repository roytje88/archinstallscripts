#!/bin/bash

function installifnotinstalled () {
    if pacman -Qs $1 > /dev/null ; then
        echo "$1 already installed."
    else
        pacman -S $1 --noconfirm
    fi
}

DMs=("lxdm lxdm" "gdm gdm" "sddm sddm")

options=""
for dm in "${DMs[@]}"; do
    options="$options $dm off "
done

dmarr=($options)

cmd=(dialog --checklist "Select which DM(s) should be installed" 22 76 16)

dmstoinstall=$("${cmd[@]}" "${dmarr[@]}" 2>&1 >/dev/tty)



for choice in $dmstoinstall; do
    installifnotinstalled $choice
    test="$(file /etc/systemd/system/display-manager.service)"
    if [[ ! $test == *"(No such file or directory)"* ]]; then
        trail="${test##*/}"
        out="${trail%.service}"
        DIALOG=$(dialog --stdout --title "Systemd service" \
                --yesno "Detected another display manager. Disable $out?" 10 70)
        response=$?
        if [ "$response" -eq 0 ]; then
            systemctl disable $out
        fi
    fi   
    DIALOG=$(dialog --stdout --title "Systemd service" \
            --yesno "Enable systemd service for $choice?" 10 70)
    response=$?
    if [ "$response" -eq 0 ]; then
        systemctl enable $choice
    fi        
done


# test="$(file /etc/systemd/system/display-manager.service)"
# echo "$test"
