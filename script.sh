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
options=(1 "Initialize pacman keyring" off
    2 "Delete user alarm" off
	3 "Modify root password" off
	4 "Create default user" off
	5 "Set a hostname" off
	6 "Set sudo settings" off
)
	
#/ Create checklist

# Show checklist
checklistchoices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)


#/ Show checklist

# Declare functions

function installifnotinstalled () {
    if pacman -Qs $1 > /dev/null ; then
        echo "$1 already installed."
    else
        pacman -S $1
    fi
}


#/ Declare functions


# Execute selected components


for choice in $checklistchoices
do
    case $choice in
    1)
        pacman-key --init
        pacman-key --populate archlinuxarm
        ;;
	2)
		userdel -r alarm
		;;
	3)
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
    4)
        username=$(dialog --inputbox "Enter the desired username for the default user" 10 30 --output-fd 1)
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
                    dialog --title "Information" --msgbox "Canceled! Password unchanged for $username!" 6 44
                    break
                fi
            done
        if [ ! -z "$check" ]; then
            echo $password | passwd --stdin
            dialog --title "Information" --msgbox "Password changed for $username!" 6 44
        fi
        ;;
    5)
        HOSTNAME=$(dialog --inputbox "What is the desired hostname?" 10 30 --output-fd 1)
        
        if [ ! -z "$HOSTNAME" ]; then
            echo $HOSTNAME > /etc/hostname
        fi
        ;;
    6)
        tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
        trap "rm -f $tempfile" 0 1 2 5 15

        dialog --radiolist "Make a choice" 22 76 16 \
            1 "use sudo with password" off  \
            2 "use sudo without password" on 2> $tempfile

        retval=$?

        choice=`cat $tempfile`
        case $retval in
          0)
            if [ "$choice" -eq 1 ]; then 
                echo "%wheel ALL=(ALL) ALL" | EDITOR="tee -a" visudo
            elif [ "$choice" -eq 2 ]; then 
                echo "%wheel ALL=(ALL) NOPASSWD: ALL" | EDITOR="tee -a" visudo
            else
                echo "ESC pressed"
            fi
            ;;
          1)
            echo "Cancel pressed.";;
          255)
            echo "ESC pressed.";;
        esac        
        ;;
    7)
        
        
        
        
    esac

done



# % dialog --backtitle "CPU Selection" \
#   --radiolist "Select CPU type:" 10 40 4 \
#         1 386SX off \
#         2 386DX on \
#         3 486SX off \
#         4 486DX off