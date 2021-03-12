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
options=(0 "Set up an SD Card for Archlinux" off
    1 "Initialize pacman keyring" off
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
    14 "Configure NFS mounts (client)" off
    15 "Set (new) locale" off
    16 "Install and configure ICAclient (Citrix Workspace)" off
    17 "Set up /boot/config.txt" off
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
        pacman -Sy $1 --noconfirm
    fi
}

function createsdcard() {

DIALOG=$(dialog --stdout --title "WARNING!!!!" \
        --yesno "Warning! Are you REALLY sure you want to reformat $1??? 
There is NO turning back!" 10 70)

response=$?
if [ "$response" -eq 0 ]; then
fdisk $1 <<EEOF
o
n                                                                                                             
p
1

+200M
t
b
n
p
2



w                                                                                                             
EEOF
fi

if [[ ! $1 == *"mmc"* ]]; then
    disk_part="/dev/$1"
else
    disk_part="/dev/${1}p"
fi

installifnotinstalled dosfstools
mkfs.vfat ${disk_part}1
mkfs.ext4 ${disk_part}2

mkdir -p /tmp/sdcard/boot /tmp/sdcard/root
mount ${disk_part}1 /tmp/sdcard/boot
mount ${disk_part}2 /tmp/sdcard/root

cd /tmp/sdcard
installifnotinstalled wget

wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-4-latest.tar.gz
bsdtar -xpf ArchLinuxARM-rpi-4-latest.tar.gz -C root
sync
mv root/boot/* boot

umount boot root

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
            echo "$username:$password" | chpasswd
            dialog --title "Information" --msgbox "Password changed for $username!" 6 44
        fi
}

function addNFSclient() {
ipaddress=$(dialog --inputbox "Enter the IP address of the NFS server." 10 30 --output-fd 1)
arr="$(showmount -e $ipaddress|grep "/24"|xargs)"
arr=(${arr})
 
foundshares=""
x=0
y=0
for i in ${arr[@]}; do
    if [[ "$x" -eq 1 ]]; then
        foundshares="$foundshares ${arr[$((y-1))]} ${arr[$((y))]} off "
        foundshares+=($str)
        x=0
        y=$((y+1))
    else
        x=$((x+1))
        y=$((y+1))
    fi
done


array=($foundshares)
cmd=(dialog --checklist "Select the share(s) to create a systemd-unit" 22 76 16)
sharesfornfs=$("${cmd[@]}" "${array[@]}" 2>&1 >/dev/tty)

for choice in $sharesfornfs; do
    mntpt=$(dialog --inputbox "Enter the default mountpoint for $choice (WITHOUTH THE LEADING SLASH! i.e. for /media/4tb, type media/4tb)" 10 30 --output-fd 1)
    
    realmountpt=$(echo "/$mntpt")
    mkdir -p $realmountpt
    systemdfile="/etc/systemd/system/$(echo "${mntpt/"/"/"-"}")"
    
    echo "[Unit]
		
Description=Things devices
After=network.target

[Mount]
What=${ipaddress}:${choice}
Where=${realmountpt}
Type=nfs
Options=_netdev,auto

[Install]
WantedBy=multi-user.target
" > ${systemdfile}.mount

    DIALOG=$(dialog --stdout --title "Systemd service" \
            --yesno "Enable systemd service for $realmountpt?" 10 70)
    response=$?
    if [ "$response" -eq 0 ]; then
        systemctl enable $(echo "${mntpt/"/"/"-"}").mount
    fi     
       
done       


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
    0)
        tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
        trap "rm -f $tempfile" 0 1 2 5 15

        hdds=()
        for hdd in $(lsblk -o KNAME,TYPE |grep disk|cut -d' ' -f1); do
            hdds=("${hdds[@]} "${hdd})
        done

        arr=""
        for hdd in $hdds; do
            arr="$arr $hdd \"$(lsblk -o SIZE,KNAME|grep $hdd|xargs|cut -d' ' -f1)\" off "
        done

        dialog --radiolist "Select the SD card" 0 0 5 \
            $arr 2> $tempfile

        retval=$?

        choice=`cat $tempfile`
        case $retval in
          0)
            createsdcard $choice
            ;;
          1)
            echo "Cancel pressed.";;
          255)
            echo "ESC pressed.";;
        esac  
        ;;
        
    1)
        pacman-key --init
        pacman-key --populate archlinuxarm
        pacman -Syu --noconfirm
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
            echo "root:$password" | chpasswd
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
        installifnotinstalled sudo
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
        installifnotinstalled git
        
        username=$(dialog --inputbox "Enter the username to install packer." 10 30 --output-fd 1)
        
        cd /tmp
        wget https://aur.archlinux.org/cgit/aur.git/snapshot/packer.tar.gz
        tar -xvf packer.tar.gz
        chown -R $username: /tmp/packer
        runuser -l $username -c "cd /tmp/packer && makepkg"
        
        pacman -U /tmp/packer/$(ls /tmp/packer|grep packer-)
        
        
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
        installifnotinstalledwithpacker plex-media-server
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

        for choice in $harddisks; do
            addfixeddisk "$choice"
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
            --radiolist "Select IP address on which to cast the NFS server" 0 0 5 \
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

    13)
        DEs=("gnome GnomeDesktop" "lxde LXDE" "mate MATE")

        options=""
        for de in "${DEs[@]}"; do
            options="$options $de off "
        done

        dearr=($options)
        cmd=(dialog --checklist "Select which Desktop environment(s) should be installed" 22 76 16)
        destoinstall=$("${cmd[@]}" "${dearr[@]}" 2>&1 >/dev/tty)

        for choice in $destoinstall; do
            installifnotinstalled $choice
        done
        ;;
    14)
        addNFSclient
        ;;
    15)
        DIALOG=$(dialog --stdout --title "Locales" \
                --yesno "Enable default locale (en_US.UTF-8)?" 10 70)
        response=$?
        if [ "$response" -eq 0 ]; then
            newlocale="en_US.UTF-8"
        elif [ "$response" -eq 1 ]; then
            newlocale=$(dialog --title "Locales" --backtitle "Set up new locale" --inputbox "Enter the desired default locale then (only **_**.UTF-8)." 10 30 --output-fd 1)
        fi
        if [ ! "$newlocale" == "" ]; then
            localectl set-locale LANG=$newlocale
            echo "$newlocale UTF-8" >> /etc/locale.gen
            locale-gen
        fi
        ;;
# chromium of firefox
    16)
#         installifnotinstalled xorg-xprop
#         installifnotinstalledwithpacker icaclient
#         echo "[Desktop Entry]
# Name=Citrix ICA client
# Categories=Network;
# Exec=/opt/Citrix/ICAClient/wfica
# Terminal=false
# Type=Application
# NoDisplay=true
# MimeType=application/x-ica;" > /usr/share/applications/wfica.desktop

#         username=$(dialog --inputbox "Enter user to configure Citrix Workspace" 10 30 --output-fd 1)
#         mkdir -p /home/${username}/.ICAClient/cache
#         cp /opt/Citrix/ICAClient/config/{All_Regions,Trusted_Region,Unknown_Region,canonicalization,regions}.ini /home/${username}/.ICAClient/

#         cd /opt/Citrix/ICAClient/keystore/cacerts/ && cp /etc/ca-certificates/extracted/tls-ca-bundle.pem . && awk 'BEGIN {c=0;} /BEGIN CERT/{c++} { print > "cert." c ".pem"}' < tls.ca-bundle.pem
#         openssl rehash /opt/Citrix/ICAClient/keystore/cacerts/
#         ln -s /usr/lib/libpcre.so.1 /usr/lib/libpcre.so.3
        
        ;;
    17)

        DIALOG=$(dialog --stdout --title "config.txt" \
                --yesno "Remove black borders (overscan)?" 10 70)
        response=$?
        if [ "$response" -eq 0 ]; then
            echo "disable_overscan=1" >> /boot/config.txt
        fi       
        
        gpumem=$(dialog --title "config.txt" --backtitle "Enter amount of GPU memory in MBs" 10 30 --output-fd 1)
        echo "gpu_mem=$gpumem" >> /boot/config.txt
        
        DIALOG=$(dialog --stdout --title "config.txt" \
                --yesno "Overclock frequency to 2000Hz?" 10 70)
        response=$?
        if [ "$response" -eq 0 ]; then
            echo "over_voltage=5
arm_freq=2000" >> /boot/config.txt
        fi       
        
        
        ;;
        
        
        
        
        
    esac

done


# #!/bin/bash
# pacman -S xorg-xprop
# runuser -l roy -c "packer -S icaclient"

# echo "[Desktop Entry]
# Name=Citrix ICA client
# Categories=Network;
# Exec=/opt/Citrix/ICAClient/wfica
# Terminal=false
# Type=Application
# NoDisplay=true
# MimeType=application/x-ica;" > /usr/share/applications/wfica.desktop


# cd /opt/Citrix/ICAClient/keystore/cacerts/
# cp /etc/ca-certificates/extracted/tls-ca-bundle.pem .
# awk 'BEGIN {c=0;} /BEGIN CERT/{c++} { print > "cert." c ".pem"}' < tls.ca-bundle.pem

# openssl rehash /opt/Citrix/ICAClient/keystore/cacerts/

# ln -s /usr/lib/libpcre.so.1 /usr/lib/libpcre.so.3

