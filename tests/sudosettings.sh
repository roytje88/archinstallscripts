#!/bin/bash   

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



# whichsudosetting=$("${cmd[@]}" "${options[@]}" 2> $tempfile) 
# echo $?
# if [[ "$whichsudosettings" = 1 ]]; then
#     echo "with pass"
# elif [[ "$whichsudosettings" -eq 2 ]]; then
#     echo "without pass"
# else
#     echo "esc or something"
#     echo $whichsudosettings
# fi
# choice=`cat $tempfile`
# echo $choice





# options=$(find ~/dir -name '*.swp' | awk '{print $1, "on"}')
# cmd=(dialog --stdout --no-items \
#         --separate-output \
#         --ok-label "Delete" \
#         --checklist "Select options:" 22 76 16)
# choices=$("${cmd[@]}" ${options})



# DIALOG=${DIALOG=dialog}
# tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
# trap "rm -f $tempfile" 0 1 2 5 15

# $DIALOG --backtitle "Select your favorite singer" \
# 	--title "My favorite singer" --clear \
#         --radiolist "Hi, you can select your favorite singer here  " 20 61 5 \
#         "Rafi"  "Mohammed Rafi" off \
#         "Lata"    "Lata Mangeshkar" ON \
#         "Hemant" "Hemant Kumar" off \
#         "Dey"    "MannaDey" off \
#         "Kishore"    "Kishore Kumar" off \
#         "Yesudas"   "K. J. Yesudas" off  2> $tempfile

# retval=$?

# choice=`cat $tempfile`
# case $retval in
#   0)
#     echo "'$choice' is your favorite singer";;
#   1)
#     echo "Cancel pressed.";;
#   255)
#     echo "ESC pressed.";;
# esac