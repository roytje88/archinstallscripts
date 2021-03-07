#!/bin/bash

dialog --title "Hostname" --msgbox "Enter the desired hostname" 6 44

while [ -z $HOSTNAME ]
do
    if [ ! $? -eq 255 ]; then
        HOSTNAME=$(dialog --inputbox "What is the desired hostname?" 10 30 --output-fd 1)
    else
        break
    fi
done