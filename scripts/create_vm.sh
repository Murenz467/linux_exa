#!/bin/bash

# create_vm.sh - Creates a new VirtualBox VM
# Usage: ./create_vm.sh <name> <os_type> <cpu_cores> <ram_mb> <storage_mb>

# Check if VBoxManage is installed
VBOXMANAGE=""
if command -v VBoxManage &> /dev/null; then
    VBOXMANAGE="VBoxManage"
elif [ -f "/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" ]; then
    VBOXMANAGE="/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
elif [ -f "/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" ]; then
    VBOXMANAGE="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
else
    echo "ERROR: VBoxManage not found. Please install VirtualBox."
    exit 1
fi

echo "Using VBoxManage: $VBOXMANAGE"

# Get parameters
VM_NAME="$1"
OS_TYPE="$2"
CPU_CORES="$3"
RAM_SIZE="$4"
STORAGE_SIZE="$5"

# Validate parameters
if [ -z "$VM_NAME" ] || [ -z "$OS_TYPE" ] || [ -z "$CPU_CORES" ] || [ -z "$RAM_SIZE" ] || [ -z "$STORAGE_SIZE" ]; then
    echo "ERROR: Missing required parameters"
    echo "Usage: $0 <name> <os_type> <cpu_cores> <ram_mb> <storage_mb>"
    exit 1
fi

# Map OS type to VirtualBox OS type
case "$OS_TYPE" in
    "Ubuntu")
        VBOX_OS_TYPE="Ubuntu_64"
        ;;
    "CentOS")
        VBOX_OS_TYPE="RedHat_64"
        ;;
    "Debian")
        VBOX_OS_TYPE="Debian_64"
        ;;
    *)
        VBOX_OS_TYPE="Linux_64"
        ;;
esac

echo "Creating VM: $VM_NAME"
echo "OS Type: $VBOX_OS_TYPE"
echo "CPU: ${CPU_CORES} cores"
echo "RAM: ${RAM_SIZE} MB"
echo "Storage: ${STORAGE_SIZE} MB"
echo "----------------------------------------"

# Create the VM
"$VBOXMANAGE" createvm --name "$VM_NAME" --ostype "$VBOX_OS_TYPE" --register

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create VM"
    exit 1
fi

# Get VM UUID and configuration file path
VM_UUID=$("$VBOXMANAGE" showvminfo "$VM_NAME" --machinereadable | grep "^UUID=" | cut -d'"' -f2)
VM_CONFIG_FILE=$("$VBOXMANAGE" showvminfo "$VM_NAME" --machinereadable | grep "^CfgFile=" | cut -d'"' -f2)

# Get the directory where the VM is stored
VM_DIR=$(dirname "$VM_CONFIG_FILE")

echo "VM Directory: $VM_DIR"
echo "VM UUID: $VM_UUID"

# Configure VM settings
"$VBOXMANAGE" modifyvm "$VM_NAME" \
    --memory "$RAM_SIZE" \
    --cpus "$CPU_CORES" \
    --vram 16 \
    --boot1 dvd \
    --boot2 disk \
    --boot3 none \
    --boot4 none \
    --nic1 nat \
    --natpf1 "ssh,tcp,,2222,,22" \
    --graphicscontroller vmsvga

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to configure VM settings"
    "$VBOXMANAGE" unregistervm "$VM_NAME" --delete
    exit 1
fi

# Create storage controller
"$VBOXMANAGE" storagectl "$VM_NAME" \
    --name "SATA Controller" \
    --add sata \
    --controller IntelAhci \
    --portcount 1 \
    --bootable on

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create storage controller"
    "$VBOXMANAGE" unregistervm "$VM_NAME" --delete
    exit 1
fi

# Create virtual hard disk path
VDI_FILE="${VM_DIR}/${VM_NAME}.vdi"
echo "Creating disk at: $VDI_FILE"

# Create virtual hard disk
"$VBOXMANAGE" createmedium disk \
    --filename "$VDI_FILE" \
    --size "$STORAGE_SIZE" \
    --format VDI

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create virtual disk"
    "$VBOXMANAGE" unregistervm "$VM_NAME" --delete
    exit 1
fi

# Attach hard disk to VM
"$VBOXMANAGE" storageattach "$VM_NAME" \
    --storagectl "SATA Controller" \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "$VDI_FILE"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to attach disk to VM"
    "$VBOXMANAGE" unregistervm "$VM_NAME" --delete
    exit 1
fi

# Add IDE controller for DVD
"$VBOXMANAGE" storagectl "$VM_NAME" \
    --name "IDE Controller" \
    --add ide

if [ $? -ne 0 ]; then
    echo "WARNING: Failed to create IDE controller"
fi

# Attach ISO file based on OS type
ISO_PATH=""

# Try to find ISO files in common locations
case "$OS_TYPE" in
    "Ubuntu")
        # Look for Ubuntu ISO in multiple locations
        for iso_file in \
            "/c/Users/fille/Downloads/ubuntu-24.04"*"-live-server-amd64.iso" \
            "/c/Users/fille/Downloads/ubuntu-25.10"*"-live-server-amd64.iso" \
            "/c/Users/fille/Downloads/ubuntu-22.04"*"-live-server-amd64.iso" \
            "/c/Users/fille/VirtualBox VMs/ISOs/ubuntu"*".iso" \
            "/c/ISOs/ubuntu"*".iso"; do
            if [ -f "$iso_file" ]; then
                ISO_PATH="$iso_file"
                break
            fi
        done
        ;;
    "Debian")
        # Look for Debian ISO (including netinst)
        for iso_file in \
            "/c/Users/fille/Downloads/debian"*"-netinst.iso" \
            "/c/Users/fille/Downloads/debian"*"-amd64-netinst.iso" \
            "/c/Users/fille/VirtualBox VMs/ISOs/debian"*".iso" \
            "/c/ISOs/debian"*".iso"; do
            if [ -f "$iso_file" ]; then
                ISO_PATH="$iso_file"
                break
            fi
        done
        ;;
    "CentOS")
        for iso_file in \
            "/c/Users/fille/Downloads/CentOS"*".iso" \
            "/c/Users/fille/VirtualBox VMs/ISOs/CentOS"*".iso" \
            "/c/ISOs/CentOS"*".iso"; do
            if [ -f "$iso_file" ]; then
                ISO_PATH="$iso_file"
                break
            fi
        done
        ;;
esac

# Also check for Alpine Linux as a lightweight alternative
if [ -z "$ISO_PATH" ] || [ ! -f "$ISO_PATH" ]; then
    for iso_file in \
        "/c/Users/fille/Downloads/alpine"*".iso" \
        "/c/Users/fille/VirtualBox VMs/ISOs/alpine"*".iso"; do
        if [ -f "$iso_file" ]; then
            ISO_PATH="$iso_file"
            echo "Using Alpine Linux as fallback"
            break
        fi
    done
fi

# Attach ISO if found
if [ -n "$ISO_PATH" ] && [ -f "$ISO_PATH" ]; then
    echo "Attaching ISO: $ISO_PATH"
    "$VBOXMANAGE" storageattach "$VM_NAME" \
        --storagectl "IDE Controller" \
        --port 0 \
        --device 0 \
        --type dvddrive \
        --medium "$ISO_PATH"
    
    if [ $? -eq 0 ]; then
        echo "ISO attached successfully"
        echo "VM will boot from ISO for OS installation"
    else
        echo "WARNING: Failed to attach ISO, but VM created"
    fi
else
    echo "WARNING: No ISO file found for $OS_TYPE"
    echo "VM created without ISO - you can attach one manually in VirtualBox"
fi

echo "----------------------------------------"
echo "VM created successfully!"
echo "VM Name: $VM_NAME"
echo "VM UUID: $VM_UUID"
echo "$VM_UUID"  # Output UUID on last line for Python to capture

exit 0