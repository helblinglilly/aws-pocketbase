# aws-pocketbase

This terraform setup will deploy up to multiple Pocketbase instances to a single EC2 instance and configure subdomains and SSL certificates as well as Cloudwatch resource alerting.

Pocketbase instances will live on a shared EBS volume separate from the OS, a snapshot of which will by default be taken every 24h and retained for 7 days. This is the only backup mechanism provided.

You will need to set up a subdomain that can be managed by AWS which your Pocketbase instances will be deployed to.

Email setup is currently not supported. You will need to provide your own SMTP server.

S3 backups within Pocketbase are not supported out of the box. You will need to provide your own S3 bucket and credentials.

## Getting set up

### With AWS

Sign into the AWS console.

To get the access keys, go to "Security Credentials" when signed into the root account. Run `aws configure` locally to get set up and insert the access key values in there. Delete those credentials once you're done - it is a bad practice for root credentials to exist.

Install [terraform](https://developer.hashicorp.com/terraform/install) or [OpenTofu](https://opentofu.org/docs/intro/install/). It will use the default aws credentials stored on your machine.

Create an S3 bucket that will store your terraform state file. Either through the web console, or by using the [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). Do not allow this bucket to be publicly accessible.

### Caution about IPv4 charges

This configuration will work with both IPv4 and v6 subnets. The module will identify your _default_ subnets unless you modify it (see `locals.tf`).

Since 1st February 2024 [AWS is now charging for each IPv4 address](https://aws.amazon.com/blogs/aws/new-aws-public-ipv4-address-charge-public-ip-insights/) in use. As Load Balancers incurr additional costs, they have been removed from this setup to minimise costs.

To avoid unexpected charges, deploy Pocketbase into an IPv6 configured subnet. See `ipv6.md` for Instructions to change this in your defaults.

## Terraform

> If you're using OpenTofu simply replace `terraform` with `tofu`

### Init

Get started with `terraform init`. If you changed the tfstate file location, add `-reconfigure`

bucket = name of the bucket you created earlier

key = name of your terraform state file: Use `terraform.tfstate` if unsure

region = the aws region you want to deploy into


### Plan

Run `terraform plan -out=tfplan` and pass any non-default values you wish to configure like this:

```
# Outdated
terraform plan
-var="budget_max_amount=[amount in USD]"
-var="ebs_backup_frequency=[amount in hours]"
-var="ebs_backup_retention_days=[days]"
-out=tfplan
```

Any other variables will get prompted. The plan will get saved into a tfplan file

### Apply

Run `terraform apply tfplan` to load the previously constructed plan and apply it.

### Post-apply

If you ran apply for the first time, you will now need to configure your AWS subdomain. A hosted zone will have been created, and one of the DNS servers that will manage that zone will be output as `hosted_zone_nameserver`. With your domain host, you will need to create an NS record for the subdomain you provided with the provided nameserver as its value. Once this is in place, AWS will verify your domain ownership and it will soon become publicly accessible.

# Architecture

## Diagram

![Architecture](architecture.png)

## Costs

These are non-binding and might differ depending on your region and setup.

Below is a price breakdown with and without AWS Free Tier based on eu-west-2 with relatively little traffic on t4g.small during its Free Trial.

Prices in USD

|Service|December 2023|December 2024|
|-|-|-|
|Total|$0.67|$6.53|
|VPC|$0.00|$3.72|
|Cloudwatch|$0.00|$0.00|
|Route53|$0.505|$0.505|
|EC2 Other|$0.06|$1.20|
|S3|$0.00|$0.007|
|Tax|$0.11|$1.09|
