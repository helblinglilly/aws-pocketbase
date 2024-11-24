resource "aws_security_group" "pocketbase_out_sg" {
  name        = "pocketbase_out_sg"
  description = "Allow Pocketbase traffic to all subnets handled by the Application Load balancer"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "Allow Pocketbase Traffic to go anywhere"
    from_port        = 443
    to_port          = 8090
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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
    description      = "Redirect http traffic to https"
    from_port        = 80
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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

# Download scripts from this repo
sudo curl https://raw.githubusercontent.com/helblinglilly/aws-pocketbase/refs/heads/main/scripts/ebs-mount.sh > ebs-mount.sh
sudo curl https://raw.githubusercontent.com/helblinglilly/aws-pocketbase/refs/heads/main/scripts/pocketbase.sh > pocketbase.sh

# Make them executable
chmod +x ebs-mount.sh
chmod +x pocketbase.sh

./ebs-mount.sh

./pocketbase.sh NAME="instance_1_name" VERSION="0.22.3" PORT="8090" DOMAIN="your.aws.managed.domain" EMAIL="user@domain.tld"
./pocketbase.sh NAME="instance_2_name" VERSION="0.22.3" PORT="8091" DOMAIN="your.other.aws.managed.domain" EMAIL="user@domain.tld"

# Scripts above restart nginx but do one more for good measure
sudo systemctl restart nginx

# Do any other setup you'd like
EOF
}
