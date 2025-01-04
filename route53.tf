resource "aws_route53_zone" "default" {
  name    = var.aws_subdomain
  comment = "Hosted zone for all AWS resources"
  tags    = var.common_tags
}


resource "aws_route53_record" "pocketbase_dub_alias_record" {
  for_each = { for idx, instance in var.pocketbase_instances : instance.name => instance }

  zone_id = aws_route53_zone.default.zone_id
  name    = "${each.key}.${var.aws_subdomain}"
  type    = "A"
  ttl     = "300"

  records = [aws_instance.pocketbase.public_ip]
}


resource "aws_route53_record" "pocketbase_dub_alias_record" {
  for_each = { for idx, instance in var.pocketbase_instances : instance.name => instance }

  zone_id = aws_route53_zone.default.zone_id
  name    = "www.${each.key}.${var.aws_subdomain}"
  type    = "A"
  ttl     = "300"

  records = [aws_instance.pocketbase.public_ip]
}
