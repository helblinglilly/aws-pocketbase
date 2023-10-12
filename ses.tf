resource "aws_ses_domain_identity" "default_domain" {
  domain = var.aws_subdomain
}

resource "aws_ses_domain_mail_from" "default" {
  domain           = aws_ses_domain_identity.default_domain.domain
  mail_from_domain = "mail.${aws_ses_domain_identity.default_domain.domain}"
}

# Verify our base domain with AWS
resource "aws_ses_domain_identity_verification" "default_verification" {
  domain     = aws_ses_domain_identity.default_domain.id
  depends_on = [aws_route53_record.ses_verification_record]
}

resource "aws_route53_record" "ses_verification_record" {
  zone_id         = aws_route53_zone.default.zone_id
  name            = "_amazonses.${aws_ses_domain_identity.default_domain.id}"
  type            = "TXT"
  ttl             = "600"
  records         = [aws_ses_domain_identity.default_domain.verification_token]
  allow_overwrite = true
}

# Create DKIM records and verify those
resource "aws_ses_domain_dkim" "default_domain_dkim" {
  domain = join("", aws_ses_domain_identity.default_domain.*.domain)
}

resource "aws_route53_record" "ses_dkim_record" {
  count           = 3
  zone_id         = aws_route53_zone.default.zone_id
  name            = "${element(aws_ses_domain_dkim.default_domain_dkim.dkim_tokens, count.index)}._domainkey.${aws_ses_domain_identity.default_domain.domain}"
  type            = "CNAME"
  ttl             = "600"
  records         = ["${element(aws_ses_domain_dkim.default_domain_dkim.dkim_tokens, count.index)}.dkim.amazonses.com"]
  allow_overwrite = true
}

# Create SPF records to verify our mail:from domain
resource "aws_route53_record" "spf_mail_from" {
  zone_id         = aws_route53_zone.default.zone_id
  name            = aws_ses_domain_mail_from.default.mail_from_domain
  type            = "MX"
  ttl             = "600"
  records         = ["10 feedback-smtp.eu-west-2.amazonses.com"]
  allow_overwrite = true
}

resource "aws_route53_record" "spf_mail_from_" {
  zone_id         = aws_route53_zone.default.zone_id
  name            = aws_ses_domain_mail_from.default.mail_from_domain
  type            = "TXT"
  ttl             = "600"
  records         = ["v=spf1 include:amazonses.com ~all"]
  allow_overwrite = true
}
