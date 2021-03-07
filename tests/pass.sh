#!/bin/bash

password=$(dialog --passwordbox "Enter the desired root password" 10 30 --output-fd 1)
confirmpw=$(dialog --passwordbox "confirm your password" 10 30 --output-fd 1)



if [ "$data" = "$confirm" ]; then
	if [ -z "$data" ]; then
		echo $data | passwd --stdin
	else
		echo "Password cannot be empty!"
else
	echo "Passwords do not match!"
fi
