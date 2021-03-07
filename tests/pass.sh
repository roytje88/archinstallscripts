#!/bin/bash

username=$(dialog --passwordbox "Enter the desired username for the default user" 10 30 --output-fd 1)

if [ ! -z "$username" ]; then
    useradd -m -g users -G wheel,storage,power -s /bin/bash $username

fi

    while [ -z "$check" ]
        do
            password=$(dialog --passwordbox "Enter the desired password for $username" 10 30 --output-fd 1)
            if [ ! $? -eq 255 ]; then
                confirmpw=$(dialog --passwordbox "confirm your password" 10 30 --output-fd 1)
            else
                dialog --title "Information" --msgbox "Canceled! Password unchanged for $username!" 6 44
                break
            fi
            if [ ! $? -eq 255 ]; then
                if [ "$password" = "$confirmpw" ]; then
                    if [ -z "$password" ]; then
                        dialog --title "Information" --msgbox "Password cannot be empty! Please try again." 6 44
                    else
                        check="not empty"
                    fi
                elif [ $? -eq 255]; then
                    dialog --title "Information" --msgbox "Canceled! Password unchanged for $username!" 6 44
                    break
                else
                    dialog --title "Information" --msgbox "Passwords do not match! Please try again." 6 44
                fi
            else
                dialog --title "Information" --msgbox "Canceled! Root password unchanged!" 6 44
                break
            fi
        done
    if [ ! -z "$check" ]; then
        echo $password | passwd --stdin
        dialog --title "Information" --msgbox "Root password changed!" 6 44
    fi

