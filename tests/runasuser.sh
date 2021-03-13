#!/bin/bash
function runasuser() {
username=$(dialog --inputbox "Enter username to execute $@" 10 30 --output-fd 1)
        runuser -l $username -c "$@"

}


runasuser "jupyter lab paths"