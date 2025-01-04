#!/bin/bash

# Download scripts from this repo
sudo curl https://raw.githubusercontent.com/helblinglilly/aws-pocketbase/refs/heads/main/scripts/ebs-mount.sh > ebs-mount.sh
sudo curl https://raw.githubusercontent.com/helblinglilly/aws-pocketbase/refs/heads/main/scripts/pocketbase.sh > pocketbase.sh

# Make them executable
chmod +x ebs-mount.sh
chmod +x pocketbase.sh

./ebs-mount.sh

%{ for instance in instances ~}
./pocketbase.sh NAME="${instance.name}" VERSION="${instance.version}" PORT="${instance.port}" DOMAIN="${instance.domain}" EMAIL="${instance.email}"
%{ endfor ~}

# Scripts above restart nginx but do one more for good measure
sudo systemctl restart nginx
