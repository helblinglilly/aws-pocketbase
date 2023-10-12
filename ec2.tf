resource "aws_security_group" "pocketbase_out_sg" {
  name        = "pocketbase_out_sg"
  description = "Allow Pocketbase traffic to all subnets handled by the Application Load balancer"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow Pocketbase Traffic to go anywhere"
    from_port   = 443
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    name = "pocketbase_out_sg"
  })
}

resource "aws_security_group" "pocketbase_http_in_sg" {
  name        = "pocketbase_http_in_sg"
  description = "Listen to http traffic and redirect it to https"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Redirect http traffic to https"
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    name = "pocketbase_http_in_sg"
  })
}


resource "aws_instance" "pocketbase" {
  ami           = "ami-0a1ab4a3fcf997a9d"
  instance_type = "t4g.small"

  availability_zone      = "${var.aws_region}b"
  vpc_security_group_ids = [aws_security_group.pocketbase_out_sg.id]

  tags = merge(var.common_tags, {
    name = "pocketbase_ec2"
  })

  user_data_replace_on_change = true
  user_data                   = <<EOF
#!/bin/bash

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

if sudo stat "/mnt/pocketbase/pocketbase" >/dev/null 2>&1; then
  sudo wget -O /mnt/pocketbase/pocketbase_source.zip https://github.com/pocketbase/pocketbase/releases/download/v0.18.9/pocketbase_0.18.9_linux_arm64.zip
  sudo unzip /mnt/pocketbase/pocketbase_source.zip
fi

# Set up Pocketbase as a systemd service
sudo touch /lib/systemd/system/pocketbase.service
echo "[Unit]
Description = pocketbase

[Service]
Type           = simple
User           = root
Group          = root
LimitNOFILE    = 4096
Restart        = always
RestartSec     = 5s
StandardOutput = append:/mnt/pocketbase/errors.log
StandardError  = append:/mnt/pocketbase/errors.log
ExecStart      = /mnt/pocketbase/pocketbase serve --http="0.0.0.0:8090"

[Install]
WantedBy = multi-user.target" | sudo tee -a /lib/systemd/system/pocketbase.service

sudo systemctl enable pocketbase.service
sudo systemctl start pocketbase

EOF
}
