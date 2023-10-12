resource "aws_route53_zone" "default" {
  name    = var.aws_subdomain
  comment = "Hosted zone for all AWS resources"
  tags    = var.common_tags
}

resource "aws_route53_record" "pocketbase_alias_record" {
  zone_id = aws_route53_zone.default.zone_id
  name    = "pocketbase.${var.aws_subdomain}"
  type    = "A"
  alias {
    name                   = aws_lb.pocketbase.dns_name
    zone_id                = aws_lb.pocketbase.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "pocketbase_dub_alias_record" {
  zone_id = aws_route53_zone.default.zone_id
  name    = "www.pocketbase.${var.aws_subdomain}"
  type    = "A"
  alias {
    name                   = aws_lb.pocketbase.dns_name
    zone_id                = aws_lb.pocketbase.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "pocketbase_acm_request" {
  domain_name               = "pocketbase.${var.aws_subdomain}"
  subject_alternative_names = ["www.pocketbase.${var.aws_subdomain}"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = var.common_tags
}

resource "aws_route53_record" "pocketbase_cert_dns" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.pocketbase_acm_request.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.pocketbase_acm_request.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.pocketbase_acm_request.domain_validation_options)[0].resource_record_type
  zone_id         = aws_route53_zone.default.zone_id
  ttl             = 60
}

resource "aws_route53_record" "pocketbase_dub_cert_dns" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.pocketbase_acm_request.domain_validation_options)[1].resource_record_name
  records         = [tolist(aws_acm_certificate.pocketbase_acm_request.domain_validation_options)[1].resource_record_value]
  type            = tolist(aws_acm_certificate.pocketbase_acm_request.domain_validation_options)[1].resource_record_type
  zone_id         = aws_route53_zone.default.zone_id
  ttl             = 60
}


resource "aws_acm_certificate_validation" "pocketbase" {
  certificate_arn         = aws_acm_certificate.pocketbase_acm_request.arn
  validation_record_fqdns = [aws_route53_record.pocketbase_cert_dns.fqdn, aws_route53_record.pocketbase_dub_cert_dns.fqdn]
}
