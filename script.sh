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
		
    esac

done




