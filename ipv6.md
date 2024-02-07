### Assign IPv6 CIDR in your VPC

1. Navigate into your AWS region of choice
2. Find the default VPC
3. From "Actions" select "Edit CIDR"
4. Add a new IPv6 range

If your Pocketbase consumers can't support IPv6 yet, you might want to keep the IPv4 range in place to ensure compatibility. Charges may apply.

### Configure subnets

You will need to repeat this step for each Subnet

1. Find your subnet (in the VPC menu)
2. From "Actions" check "Enable auto-assign IPv6 address"
   1. Un-tick the public IPv4 setting if you want to disable IPv4
3. From "Actions" select "Edit IPv6 CIDRs"
   1. Add your VPCs CIDR range
   2. Assign a subset of that CIDR range to the Subnet
