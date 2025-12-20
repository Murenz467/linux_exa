#!/bin/bash

VM_NAME=$1

# Find VBoxManage
VBOXMANAGE=""
if command -v VBoxManage &> /dev/null; then
    VBOXMANAGE="VBoxManage"
elif [ -f "/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" ]; then
    VBOXMANAGE="/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
elif [ -f "/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" ]; then
    VBOXMANAGE="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
else
    echo "ERROR: VBoxManage not found"
    exit 1
fi

# Check if already running
if "$VBOXMANAGE" showvminfo "$VM_NAME" --machinereadable | grep -q "VMState=\"running\""; then
    echo "VM is already running."
    exit 0
fi

# Start the VM in headless mode
"$VBOXMANAGE" startvm "$VM_NAME" --type headless

echo "SUCCESS"