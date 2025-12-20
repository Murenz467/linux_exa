#!/bin/bash

VM_NAME=$1

# Find VBoxManage
VBOXMANAGE=""
if command -v VBoxManage &> /dev/null; then
    VBOXMANAGE="VBoxManage"
elif [ -f "/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" ]; then
    VBOXMANAGE="/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
fi

# Start VM with GUI
"$VBOXMANAGE" startvm "$VM_NAME" --type gui

exit 0