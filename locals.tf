data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "subnets_default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "subnet_default_a" {
  availability_zone = "${var.aws_region}a"
  vpc_id            = data.aws_vpc.default.id
}

data "aws_subnet" "subnet_default_b" {
  availability_zone = "${var.aws_region}b"
  vpc_id            = data.aws_vpc.default.id
}

data "aws_subnet" "subnet_default_c" {
  availability_zone = "${var.aws_region}c"
  vpc_id            = data.aws_vpc.default.id
}
