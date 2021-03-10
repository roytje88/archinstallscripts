#!/bin/bash



test="/etc/systemd/system/display-manager.service: symbolic link to /lib/systemd/system/lxdm.service"

if [[ ! $test == *"(No such file or directory)"* ]]; then
    trail="${test##*/}"
    out="${trail%.service}"
    DIALOG=$(dialog --stdout --title "Systemd service" \
            --yesno "Detected another display manager. Disable $out?" 10 70)
    response==$?
    if [ "$response" -eq 0 ]; then
        systemctl disable $out
    fi
fi
