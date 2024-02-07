resource "aws_vpc_ipam" "main" {
  description = "Default IPAM"
  operating_regions {
    region_name = var.aws_region
  }
}