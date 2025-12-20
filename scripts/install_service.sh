#!/bin/bash

# install_service.sh - Install a service on a VirtualBox VM
# Usage: ./install_service.sh <vm_name> <service_name>

VM_NAME="$1"
SERVICE_NAME="$2"

# Validate parameters
if [ -z "$VM_NAME" ] || [ -z "$SERVICE_NAME" ]; then
    echo "ERROR: Missing required parameters"
    echo "Usage: $0 <vm_name> <service_name>"
    exit 1
fi

echo "Installing service: $SERVICE_NAME on VM: $VM_NAME"
echo "----------------------------------------"

# Check if VM exists
if ! VBoxManage list vms | grep -q "\"$VM_NAME\"" 2>/dev/null; then
    echo "WARNING: VM '$VM_NAME' not found"
fi

# Simulate service installation
case "$SERVICE_NAME" in
    "nginx")
        echo "Simulating Nginx installation..."
        echo "Commands that would run on the VM:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y nginx"
        echo "  sudo systemctl start nginx"
        echo "  sudo systemctl enable nginx"
        ;;
    "apache")
        echo "Simulating Apache installation..."
        echo "Commands that would run on the VM:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y apache2"
        echo "  sudo systemctl start apache2"
        echo "  sudo systemctl enable apache2"
        ;;
    "mysql")
        echo "Simulating MySQL installation..."
        echo "Commands that would run on the VM:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y mysql-server"
        echo "  sudo systemctl start mysql"
        echo "  sudo systemctl enable mysql"
        ;;
    "postgresql")
        echo "Simulating PostgreSQL installation..."
        echo "Commands that would run on the VM:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y postgresql"
        echo "  sudo systemctl start postgresql"
        echo "  sudo systemctl enable postgresql"
        ;;
    "docker")
        echo "Simulating Docker installation..."
        echo "Commands that would run on the VM:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y docker.io"
        echo "  sudo systemctl start docker"
        echo "  sudo systemctl enable docker"
        ;;
    "git")
        echo "Simulating Git installation..."
        echo "Commands that would run on the VM:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y git"
        ;;
    "python3")
        echo "Simulating Python 3 installation..."
        echo "Commands that would run on the VM:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y python3 python3-pip"
        ;;
    "nodejs")
        echo "Simulating Node.js installation..."
        echo "Commands that would run on the VM:"
        echo "  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
        echo "  sudo apt-get install -y nodejs"
        ;;
    *)
        echo "Simulating installation of: $SERVICE_NAME"
        ;;
esac

# Simulate a delay
sleep 2

echo "----------------------------------------"
echo "SUCCESS: Service '$SERVICE_NAME' installed (simulated)"

exit 0