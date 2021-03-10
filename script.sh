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
    7 "Install packer (aur helper)" off
    8 "Install and configure NZBget" off
    9 "Install Plex Media Server" off
    10 "Create fixed mountpoints for harddisks" off
    11 "Set up NFS server" off
    12 "Install and configure a display manager" off
    13 "Install and configure a desktop environment" off
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
        pacman -S $1 --noconfirm
    fi
}

function installifnotinstalledwithpacker () {
    if pacman -Qs $1 > /dev/null ; then
        echo "$1 already installed."
    else
        username=$(dialog --inputbox "Enter user to install $1" 10 30 --output-fd 1)
        runuser -l $username -c "packer -S $1 --noconfirm"
    fi
}


createUser() {
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
}


function addfixeddisk() {
mountpt=$(dialog --title "Harddisks" --backtitle "Set fixed mountpoints for harddisks" --inputbox "Enter the desired mountpoint for $1, "$(lsblk -o SIZE,KNAME|grep $1|xargs|cut -d' ' -f1)" (i.e. /media/harddisk)." 10 30 --output-fd 1)

echo "UUID=\"$(blkid -o value -s UUID /dev/$1)\" $mountpt ext4 defaults 0 0" >> /etc/fstab
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
        createUser
        
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
        installifnotinstalled wget
        installifnotinstalled base-devel
        installifnotinstalled jshon 
        installifnotinstalled expac
        
        username=$(dialog --inputbox "Enter the username to install packer." 10 30 --output-fd 1)
        
        cd /tmp
        wget https://aur.archlinux.org/cgit/aur.git/snapshot/packer.tar.gz
        tar -xvf packer.tar.gz
        chown -R $username: /tmp/packer
        runuser -l $username -c "cd /tmp/packer && makepkg"
        
        sudo pacman -U /tmp/packer/$(ls /tmp/packer|grep packer-)
        
        
        ;;
        
    8)
        installifnotinstalled nzbget-systemd
        installifnotinstalled par2cmdline
        installifnotinstalled unrar
        
        DIALOG=$(dialog --stdout --title "Systemd service" \
            --yesno "Enable systemd service for NZBget?" 10 70)
        response=$?
        if [ "$response" -eq 0 ]; then
            systemctl enable nzbget
        fi
        
        ;;
     9)
        installifnotinstalled plex-media-server
        DIALOG=$(dialog --stdout --title "Systemd service" \
            --yesno "Enable systemd service for Plex?" 10 70)
        response=$?
        if [ "$response" -eq 0 ]; then
            systemctl enable plexmediaserver
        fi
        
        ;;
        
    10)
        hdds=()
        for hdd in $(lsblk -o KNAME,TYPE |grep part|cut -d' ' -f1); do
            hdds=("${hdds[@]} "${hdd})
        done

        arr=""
        for hdd in $hdds; do
            arr="$arr $hdd \"$(lsblk -o SIZE,KNAME|grep $hdd|xargs|cut -d' ' -f1)\" off "
        done

        hddarr=($arr)

        dialogcmd=(dialog --checklist "Select for which harddisk(s) a fixed mountpoint should be created." 22 76 16)

        harddisks=$("${dialogcmd[@]}" "${hddarr[@]}" 2>&1 >/dev/tty)

        if [ ! $? -eq 255 ]; do
            for choice in $harddisks; do
                addfixeddisk "$choice"
            done
        else
            echo "Canceled!"
        done     

        ;;
    11)
        installifnotinstalled nfs-utils
        share=$(dialog --title "NFS" --backtitle "Set up NFS server" --inputbox "Enter the name of the folder to create and share (i.e. /srv/media/harddisk)." 10 30 --output-fd 1)
        actualfolder=$(dialog --title "NFS" --backtitle "Set up NFS server" --inputbox "Enter the name of the folder to bind to the shared folder (i.e. /media/harddisk)." 10 30 --output-fd 1)
        
        ips=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
        arr=""
        for ip in $ips; do
            arr="$arr $ip IP off "
        done

        tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
        trap "rm -f $tempfile" 0 1 2 5 15


        dialog --backtitle "Test" \
            --radiolist "test" 0 0 5 \
            $arr 2> $tempfile

        retval=$?

        choice=`cat $tempfile`
        case $retval in
          0)
            mkdir -p $share
            echo "$actualfolder $share none bind 0 0" >> /etc/fstab
            echo "$share $choice/24(rw,no_subtree_check,nohide,sync,no_root_squash,insecure,no_auth_nlm)" >> /etc/exports
            exportfs -rav
            ;;
          1)
            echo "Cancel pressed.";;
          255)
            echo "ESC pressed.";;
        esac  
        ;;
    
    12)
        installifnotinstalled sudo
        installifnotinstalled alsa-utils
        installifnotinstalled mesa
        installifnotinstalled xf86-video-fbdev
        installifnotinstalled dosfstools
        
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
        ;;



# chromium of firefox
    
    esac

done
