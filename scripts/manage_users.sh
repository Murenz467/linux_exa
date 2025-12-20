#!/bin/bash

# manage_users.sh - Create a user on a VirtualBox VM
# Usage: ./manage_users.sh <vm_name> <username> <password> <sudo_access>

VM_NAME="$1"
USERNAME="$2"
PASSWORD="$3"
SUDO_ACCESS="$4"  # "yes" or "no"

# Validate parameters
if [ -z "$VM_NAME" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$SUDO_ACCESS" ]; then
    echo "ERROR: Missing required parameters"
    echo "Usage: $0 <vm_name> <username> <password> <sudo_access>"
    exit 1
fi

echo "Creating user: $USERNAME on VM: $VM_NAME"
echo "Sudo access: $SUDO_ACCESS"
echo "----------------------------------------"

# Check if VM exists
if ! VBoxManage list vms | grep -q "\"$VM_NAME\"" 2>/dev/null; then
    echo "WARNING: VM '$VM_NAME' not found"
fi

# Simulate user creation
echo "Simulating user creation..."
echo "Commands that would run on the VM:"
echo ""
echo "  # Create user"
echo "  sudo useradd -m -s /bin/bash $USERNAME"
echo ""
echo "  # Set password"
echo "  echo '$USERNAME:$PASSWORD' | sudo chpasswd"
echo ""

if [ "$SUDO_ACCESS" = "yes" ]; then
    echo "  # Add user to sudo group"
    echo "  sudo usermod -aG sudo $USERNAME"
    echo ""
fi

echo "  # Create SSH directory"
echo "  sudo mkdir -p /home/$USERNAME/.ssh"
echo "  sudo chown $USERNAME:$USERNAME /home/$USERNAME/.ssh"
echo "  sudo chmod 700 /home/$USERNAME/.ssh"

# Simulate a delay
sleep 1

echo ""
echo "----------------------------------------"
echo "SUCCESS: User '$USERNAME' created (simulated)"
if [ "$SUDO_ACCESS" = "yes" ]; then
    echo "User has sudo privileges"
else
    echo "User does not have sudo privileges"
fi

echo ""
echo "NOTE: This is a simplified simulation for the project."

exit 0