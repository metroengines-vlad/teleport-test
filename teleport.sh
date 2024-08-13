#!/bin/bash

# echo Linking Teleport with WSL...
if grep -q "microsoft" /proc/version; then
    echo "WSL Confirmed."
else
    echo "Not running on WSL!!! This script only makes sense to execute from WSL."
    exit 1
fi

WIN_IP=$(ip route | grep '^default' | awk '{print $3}')
ALIAS="teleport"

if [ -z "$WIN_IP" ]; then
    echo "Failed to extract Windows host IP address"
    exit 1
fi

echo "Make sure we have a /etc/hosts Alias ($ALIAS) for the Windows Host ($WIN_IP)..."

# Backup the current /etc/hosts file
sudo cp /etc/hosts /etc/hosts.bak

# Remove any existing entry for the alias in /etc/hosts
sudo sed -i "/\b$ALIAS\b/d" /etc/hosts

# Add the new entry for the alias
echo "$WIN_IP    $ALIAS" | sudo tee -a /etc/hosts > /dev/null

cat /etc/hosts
# echo "Updated /etc/hosts with $WIN_IP as $ALIAS"

echo Set up the Windows side...
powershell.exe -ExecutionPolicy Bypass -File "link-teleport.ps1"
