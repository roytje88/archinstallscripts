#!/bin/bash

welcome=$(dialog --stdout --title "Arch install script for the Raspberry Pi" \
	--backtitle "Backtitle" \
	--yesno "Welcome to the installation script for the Raspberry Pi 4.
First I need to have some information. 
Would you like to continue?" 10 70)
response=$?

	if [ ! "$response" -eq 0 ]; then
		dialog --title "Information" --msgbox "False" 6 44

	fi


