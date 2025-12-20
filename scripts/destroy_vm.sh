#!/bin/bash

VM_NAME=$1

# Check if VM exists
if ! VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    echo "Error: VM $VM_NAME does not exist."
    exit 1
fi

# Check if running and power off if needed
if VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -q "VMState=\"running\""; then
    VBoxManage controlvm "$VM_NAME" poweroff
    sleep 2 # Wait for it to shut down
fi

# Delete the VM and all its files (including hard disks)
VBoxManage unregistervm "$VM_NAME" --delete

echo "SUCCESS"