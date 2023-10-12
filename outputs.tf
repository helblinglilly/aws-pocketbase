output "hosted_zone_nameserver" {
  description = "Create an NS record in your domain provider for your var.aws_subdomain to point at this server"
  value       = aws_route53_zone.default.primary_name_server
}

output "pocketbase_url" {
  description = "URL that pocketbase has been deployed to"
  value       = aws_route53_record.pocketbase_alias_record.name
}
