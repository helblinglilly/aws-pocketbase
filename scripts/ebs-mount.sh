#!/bin/bash

# Set up
while [ ! -e /dev/nvme1n1 ]; do
  echo "Waiting for EBS volume to be attached..."
  sleep 10
done

if sudo stat "/mnt/pocketbase" >/dev/null 2>&1; then
  echo "Folder exists."
else
    echo "Folder does not exist. New root file system"
    sudo mkdir /mnt/pocketbase
    # Configure the EBS volume to be automatically mounted
    echo "/dev/nvme1n1  /mnt/pocketbase  ext4  defaults,nofail  0  2" | sudo tee -a /etc/fstab
fi

if ! sudo blkid /dev/nvme1n1; then
  # EBS has no file system - create one
  sudo mkfs -t ext4 /dev/nvme1n1
fi

sudo mount /dev/nvme1n1 /mnt/pocketbase

# Dependencies for reverse proxy
sudo yum update -y
sudo yum install nginx -y

# Dependencies for letsencrypt
sudo yum install python3-pip -y
sudo pip3 install certbot certbot-nginx

sudo systemctl enable nginx
