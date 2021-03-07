#!/bin/bash

# Welcome screen
welcome=$(dialog --stdout --title "Arch install script for the Raspberry Pi" \
	--backtitle "Arch install script for the Raspberry Pi" \
	--yesno "Welcome to the installation script for the Raspberry Pi 4.
This script can also be run to install and/or configure separate components.

Would you like to continue?" 10 70)
response=$?
	if [ ! "$response" -eq 0 ]; then
		dialog --title "Cancelled!" --msgbox "Exiting..." 6 44
		exit 0		
	fi

#/ Welcome screen

# Create checklist
cmd=(dialog --separate-output --checklist "Select components" 22 76 16)
options=(1 "Delete user alarm" off
	2 "Modify root password" off
	3 "Create default user" off
	4 "Set a hostname" off
	5 "Set sudo settings" off
)
	
#/ Create checklist

# Show checklist
checklistchoices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)


#/ Show checklist

# Execute selected components


for choice in $checklistchoices
do
    case $choice in
	1)
		userdel -r alarm
		;;
	2)
        while [ -z "$check" ]
            do
                password=$(dialog --passwordbox "Enter the desired root password" 10 30 --output-fd 1)
                if [ ! $? -eq 255 ]; then
                    confirmpw=$(dialog --passwordbox "confirm your password" 10 30 --output-fd 1)
                else
                    dialog --title "Information" --msgbox "Canceled! Root password unchanged!" 6 44
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
                        dialog --title "Information" --msgbox "Canceled! Root password unchanged!" 6 44
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
        ;;
        
    esac

done




