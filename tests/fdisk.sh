#!/bin/bash




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

+50M
t
b
n
p
2



w                                                                                                             
EEOF
fi

}

createsdcard test.img
