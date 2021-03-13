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
    18 "Create MySQL database for Kodi" off
    19 "Install Spotweb" off
    20 "set correct timezone (Europe/Amsterdam)" off
    21 "Enable Numlock on boot" off
    22 "Install JupyterLab" off
    23 "Install and configure Mopidy" off
    24 "Install Pi-Hole" off
    25 "Install Home Assistant" off
    26 "Install Nginx (including certbot)" off
    
)
	
    
cmdcustompackages=(dialog --separate-output --checklist "Select custom packages to install" 22 76 16)
optionscustompackages=(1 "chromium" off
    2 "firefox" off
    3 "gnome-extra" off
    4 "pulseaudio" off
    5 "pulseaudio-alsa" off)
#/ Create checklist

# Show checklist
checklistchoices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)


#/ Show checklist

# Declare functions

function runasuser() {
username=$(dialog --inputbox "Enter username to execute $@" 10 30 --output-fd 1)
        runuser -l $username -c "$@"

}

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
pacman -S nfs-utils
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


function configuresql() {
        installationfile="/var/lib/mysql_installed"
        if [ ! -f "$installationfile" ]; then
            pacman -Syu --noconfirm apache php-apache mariadb php-gd
            mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
            systemctl start mariadb
            mysql_secure_installation
            touch $installationfile
            systemctl enable mariadb
        fi
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
        pacman -S base-devel
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
        pacman -S nfs-utils
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
	installifnotinstalled lxterminal
        DEs=("gnome GnomeDesktop" "lxde LXDE" "mate MATE")

        options=""
        for de in "${DEs[@]}"; do
            options="$options $de off "
        done

        dearr=($options)
        cmd=(dialog --checklist "Select which Desktop environment(s) should be installed" 22 76 16)
        destoinstall=$("${cmd[@]}" "${dearr[@]}" 2>&1 >/dev/tty)

        for choice in $destoinstall; do
            pacman -S $choice
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

    16)
        echo "Last time there were some troubles. Please try to install manually."
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
        
        gpumem=$(dialog --title "config.txt" --backtitle "GPU Memory" --inputbox "Enter amount of GPU memory in MBs" 10 30 --output-fd 1)
        echo "gpu_mem=$gpumem" >> /boot/config.txt
        
        DIALOG=$(dialog --stdout --title "config.txt" \
                --yesno "Overclock frequency to 2000Hz?" 10 70)
        response=$?
        if [ "$response" -eq 0 ]; then
            echo "over_voltage=5
arm_freq=2000" >> /boot/config.txt
        fi       
        
        DIALOG=$(dialog --stdout --title "config.txt" \
                --yesno "Enable audio 3.5mm?" 10 70)
        response=$?
        if [ "$response" -eq 0 ]; then
            echo "dtparam=audio=on" >> /boot/config.txt
        fi 
        

        ;;
        
    18)
        configuresql
        echo "CREATE USER 'kodi' IDENTIFIED BY 'kodi';
GRANT ALL ON *.* TO 'kodi';
flush privileges;" > tmp.sql
        mysql < tmp.sql
        rm tmp.sql
        
        ;;
    19)
        configuresql
        pacman -S php7-apache
        pacman -S php7-gd
        pacman -S cronie
        sed -i 's/;date.timezone =/date.timezone = Europe\/Amsterdam/g' /etc/php7/php.ini
        sed -i 's/;extension=gd/extension=gd/g' /etc/php7/php.ini
        sed -i 's/;extension=mysqli/extension=mysqli/g' /etc/php7/php.ini
        sed -i 's/;extension=gettext/extension=gettext/g' /etc/php7/php.ini
        sed -i 's/;extension=pdo_mysql/extension=pdo_mysql/g' /etc/php7/php.ini
        
        sed -i 's/#LoadModule rewrite_module modules\/mod_rewrite.so/LoadModule rewrite_module modules\/mod_rewrite.so/g' /etc/httpd/conf/httpd.conf
        sed -i 's/LoadModule mpm_event_module modules\/mod_mpm_event.so/#LoadModule mpm_event_module modules\/mod_mpm_event.so/g' /etc/httpd/conf/httpd.conf
        sed -i 's/#LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/g' /etc/httpd/conf/httpd.conf
        sed -i '/LoadModule rewrite_module modules\/mod_rewrite.so/aLoadModule php7_module modules\/libphp7.so' /etc/httpd/conf/httpd.conf            
        sed -i '/LoadModule php7_module modules\/libphp7.so/aAddHandler php7-script .php' /etc/httpd/conf/httpd.conf
        sed -i '/Include conf\/extra\/httpd-default.conf/aInclude conf\/extra\/php7_module.conf' /etc/httpd/conf/httpd.conf
        systemctl start httpd
        echo "CREATE DATABASE spotweb;
CREATE USER 'spotweb'@'localhost' IDENTIFIED BY 'spotweb';
GRANT ALL PRIVILEGES ON spotweb.* TO spotweb@localhost IDENTIFIED BY 'spotweb';" > tmp.sql
        mysql -u root -p < tmp.sql
        rm tmp.sql
        chmod -R 777 /srv/http/
        cd /srv/http/
        git clone https://github.com/spotweb/spotweb.git
        systemctl restart httpd
        echo "Go to http://localhost/spotweb/install.php 
        Press [ENTER] to continue"
        read dummy
        crontab -l cron.tmp
        echo "*/14 * * * * php /srv/http/spotweb/retrieve.php --force" >> cron.tmp
        crontab cron.tmp
        rm cron.tmp
        systemctl enable httpd
        systemctl enable cronie --now
        
        echo "<IfModule mod_rewrite.c>
        RewriteEngine on
        RewriteCond %{REQUEST_URI} !api/
        RewriteBase /spotweb/
        RewriteRule api/?$ index.php?page=newznabapi [QSA,L]
        RewriteRule details/([^/]+) index.php?page=getspot&messageid=$1 [L]
</IfModule>" > /srv/http/spotweb/.htaccess
        echo "Manually set AllowOverride to All in /etc/httpd/conf/httpd.conf!"
        read dummy
        nano /etc/httpd/conf/httpd.conf
        
        ;;
    20)
        timedatectl set-timezone Europe/Amsterdam
        timedatectl set-local-rtc 1
        
        
        
        ;;
    21)
        installifnotinstalledwithpacker systemd-numlockontty
        systemctl enable numLockOnTty 
        ;;
    22)
        installifnotinstalled jupyterlab
        runasuser "export JUPYTERLAB_DIR=$HOME/.local/share/jupyter/lab"
        runasuser "jupyter lab build"
        
        ;;
    23)
    	pacman -S mopidy
    	
    	installifnotinstalledwithpacker mopidy-mpd
    	echo "

[mpd]
hostname = ::
enabled = true
server = "$(cat /etc/hostname)"

" >> /etc/mopidy/mopidy.conf
	
    	echo "
    	
[http]
enabled = true
hostname = ::       
port = 6680
zeroconf = Mopidy HTTP server on $hostname
csrf_protection = true
default_app = mopidy

" >> /etc/mopidy/mopidy.conf

    	installifnotinstalledwithpacker mopidy-musicbox
    	
    	echo "
    	
[musicbox_webclient]
enabled = true
musicbox = true 
on_track_click = PLAY_ALL

" >> /etc/mopidy/mopidy.conf
	
	
	installifnotinstalledwithpacker mopidy-alsamixer
	echo "Possible error when installing mopidy-alsamixer. Please fix in another terminal and press enter when installed!"
	read dummy
    	
    	echo "
    	
[audio]
mixer = alsamixer

" >> /etc/mopidy/mopidy.conf    	
    	
    	
    	systemctl enable mopidy --now
    	
    	;;
    24)
    
    	installifnotinstalledwithpacker pi-hole-server
    	pacman -S lighttpd php-sqlite php-cgi php-fpm php7-fpm --noconfirm
    	
    	sed -i 's/DNSStubListener=yes/DNSStubListener=yes/g' /etc/systemd/resolved.conf
    	sed -i 's/#DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
    	cp /usr/share/pihole/configs/lighttpd.example.conf /etc/lighttpd/lighttpd.conf
    	sed -i 's/server.port                 = 80/server.port                 = 81/g' /etc/lighttpd/lighttpd.conf
        sed -i 's/;extension=pdo_sqlite/extension=pdo_sqlite/g' /etc/php7/php.ini
        sed -i 's/;extension=sockets/extension=sockets/g' /etc/php7/php.ini
        sed -i 's/;extension=sqlite3/extension=sqlite3/g' /etc/php7/php.ini


    	mkdir -p /etc/systemd/system/php-fpm.service.d
    	echo "[Service]
ReadWritePaths = /srv/http/pihole
ReadWritePaths = /run/pihole-ftl/pihole-FTL.port
ReadWritePaths = /run/log/pihole/pihole.log
ReadWritePaths = /run/log/pihole-ftl/pihole-FTL.log
ReadWritePaths = /etc/pihole
ReadWritePaths = /etc/hosts
ReadWritePaths = /etc/hostname
ReadWritePaths = /etc/dnsmasq.d/
ReadWritePaths = /proc/meminfo
ReadWritePaths = /proc/cpuinfo
ReadWritePaths = /sys/class/thermal/thermal_zone0/temp
ReadWritePaths = /tmp" >> /etc/systemd/system/php-fpm.service.d/pihole.conf

    	systemctl restart systemd-resolved pihole-FTL
    	systemctl enable pihole-FTL
    	systemctl enable lighttpd --now
    	
    	
    	
    	
    	    	
    	;;
 
 
 
 
 
    25)
	   installifnotinstalled home-assistant
	
	
 	      ;;
 	
    26)
    
    	
    	installifnotinstalled certbot
    	installifnotinstalled nginx
    	installifnotinstalled certbot-nginx
    	mkdir /etc/nginx/ssl
    	cd /etc/nginx/ssl
    	openssl req -new -x509 -nodes -newkey rsa:4096 -keyout server.key -out server.crt -days 1095
    	chmod 400 server.key
    	chmod 400 server.crt
    	
    	servername=$(dialog --title "Nginx" --inputbox "Enter the name of the server (i.e. example.com)" 10 30 --output-fd 1)
    	
#    	echo "
#worker_processes  1;
#
#
#events {
#    worker_connections  1024;
#}    	
#    http {
#    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
#    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
#
#    # Redirect to HTTPS
#    server {
#        listen 82;
#        server_name ${servername};
#        return 301 https://$host$request_uri;
#    }
#
#
#
#
#}
#" > /etc/nginx/nginx.conf
#
    	
        ;;
    	
done


