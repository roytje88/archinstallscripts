#!/bin/bash

addNFSclient() {
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


addNFSclient