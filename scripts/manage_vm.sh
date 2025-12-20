#!/bin/bash

# Script to manage VirtualBox VMs (start/stop/status)
# Usage: ./manage_vm.sh <action> <vm_name>

ACTION=$1
VM_NAME=$2

if [ -z "$ACTION" ] || [ -z "$VM_NAME" ]; then
    echo "ERROR: Missing required parameters"
    echo "Usage: $0 <start|stop|poweroff|status> <vm_name>"
    exit 1
fi

# Check if VirtualBox is installed
if ! command -v VBoxManage &> /dev/null; then
    echo "ERROR: VirtualBox is not installed"
    exit 1
fi

# Check if VM exists
if ! VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    echo "ERROR: VM '$VM_NAME' does not exist"
    exit 1
fi

echo "Managing VM: $VM_NAME"
echo "Action: $ACTION"
echo "----------------------------------------"

case $ACTION in
    start)
        echo "Starting VM: $VM_NAME (headless mode)"
        VBoxManage startvm "$VM_NAME" --type headless
        if [ $? -eq 0 ]; then
            echo "VM started successfully"
            echo "SUCCESS"
            exit 0
        else
            echo "ERROR: Failed to start VM"
            exit 1
        fi
        ;;
    
    stop)
        echo "Stopping VM: $VM_NAME (ACPI shutdown)"
        VBoxManage controlvm "$VM_NAME" acpipowerbutton
        if [ $? -eq 0 ]; then
            echo "Shutdown signal sent successfully"
            echo "SUCCESS"
            exit 0
        else
            echo "ERROR: Failed to stop VM"
            exit 1
        fi
        ;;
    
    poweroff)
        echo "Powering off VM: $VM_NAME (force)"
        VBoxManage controlvm "$VM_NAME" poweroff
        if [ $? -eq 0 ]; then
            echo "VM powered off successfully"
            echo "SUCCESS"
            exit 0
        else
            echo "ERROR: Failed to power off VM"
            exit 1
        fi
        ;;
    
    status)
        STATE=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "^VMState=" | cut -d'"' -f2)
        echo "VM Status: $STATE"
        exit 0
        ;;
    
    *)
        echo "ERROR: Invalid action '$ACTION'"
        echo "Valid actions: start, stop, poweroff, status"
        exit 1
        ;;
esac