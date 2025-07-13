resource "aws_route53_zone" "baylenwebsite" {
  name = var.route53_domain_name
}

resource "aws_route53_record" "cert_validation" {
  # Iterate over each domain validation option from your certificate
  for_each = { for dvo in var.domain_validation_options : dvo.domain_name => dvo }

  # The hosted zone in which to create the record.
  zone_id = aws_route53_zone.baylenwebsite.zone_id

  # The record name provided by ACM for DNS validation.
  name    = each.value.resource_record_name

  # The DNS record type (it could be TXT or CNAME depending on your certificate configuration).
  type    = each.value.resource_record_type

  # The record value required for validation.
  records = [each.value.resource_record_value]

  # Time to live for the record.
  ttl     = 60
}

resource "aws_route53_record" "alias_record" {
  zone_id = aws_route53_zone.baylenwebsite.zone_id
  name    = var.route53_domain_name  # This will be your apex domain (e.g., "baylenwebsite.xyz"); change if needed.
  type    = "A"

  alias {
    name                   = var.cloudfront_distribution_domain_name
    zone_id                = var.cloudfront_distribution_hosted_zone_id  # For CloudFront, this is typically "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ses_verification" {
  zone_id = aws_route53_zone.baylenwebsite.zone_id
  name    = "_amazonses.${var.route53_domain_name}"
  type    = "TXT"
  ttl     = 600
  records = [var.ses_domain_identity_verification_token]
}
