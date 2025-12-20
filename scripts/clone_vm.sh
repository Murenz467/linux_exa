#!/bin/bash

# clone_vm.sh - Clone an existing VM
# Usage: ./clone_vm.sh <source_vm_name> <new_vm_name>

SOURCE_VM=$1
NEW_VM=$2

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

if [ -z "$SOURCE_VM" ] || [ -z "$NEW_VM" ]; then
    echo "ERROR: Missing required parameters"
    echo "Usage: $0 <source_vm_name> <new_vm_name>"
    exit 1
fi

# Check if source VM exists
if ! "$VBOXMANAGE" list vms | grep -q "\"$SOURCE_VM\""; then
    echo "ERROR: Source VM '$SOURCE_VM' does not exist"
    exit 1
fi

# Check if new VM name already exists
if "$VBOXMANAGE" list vms | grep -q "\"$NEW_VM\""; then
    echo "ERROR: VM '$NEW_VM' already exists"
    exit 1
fi

echo "Cloning VM: $SOURCE_VM -> $NEW_VM"
echo "This may take a few minutes..."

# Clone the VM
"$VBOXMANAGE" clonevm "$SOURCE_VM" \
    --name "$NEW_VM" \
    --register

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to clone VM"
    exit 1
fi

# Get new VM UUID
NEW_UUID=$("$VBOXMANAGE" showvminfo "$NEW_VM" --machinereadable | grep "^UUID=" | cut -d'"' -f2)

echo "VM cloned successfully!"
echo "New VM: $NEW_VM"
echo "New UUID: $NEW_UUID"
echo "$NEW_UUID"

exit 0