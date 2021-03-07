#!/bin/bash

MYVAR=$(dialog --inputbox "THIS OUTPUT GOES TO FD 1" 25 25  --output-fd 1)

echo $MYVAR

