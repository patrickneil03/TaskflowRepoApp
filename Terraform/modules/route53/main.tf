data "aws_route53_zone" "shared_domain" {
  name         = var.route53_domain_name
  private_zone = false
}

# --- 1. EXISTING: API Gateway Certificate DNS Validation ---
resource "aws_route53_record" "cert_validation" {
  for_each = { for dvo in var.domain_validation_options : dvo.domain_name => dvo }

  zone_id = data.aws_route53_zone.shared_domain.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

# --- 2. ADDED: Cognito Certificate DNS Validation ---
resource "aws_route53_record" "cognito_cert_validation" {
  # Loops through the Cognito certificate domain options passed from the ACM module
  for_each = { for dvo in var.domain_validation_options_cognito : dvo.domain_name => dvo }

  zone_id = data.aws_route53_zone.shared_domain.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

# --- 3. EXISTING: SES Verification ---
resource "aws_route53_record" "ses_verification" {
  zone_id = data.aws_route53_zone.shared_domain.zone_id
  name    = "_amazonses.${var.route53_domain_name}" 
  type    = "TXT"
  ttl     = 600
  records = [var.ses_domain_identity_verification_token]
}

# --- 4. EXISTING: API DNS Routing ---
resource "aws_route53_record" "api_dns" {
  name    = var.custom_domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.shared_domain.zone_id

  alias {
    evaluate_target_health = true
    name                   = var.regional_domain_name
    zone_id                = var.regional_zone_id
  }
}

# --- 5. ADDED: Cognito Custom Domain DNS Routing ---
resource "aws_route53_record" "cognito_dns" {
  name    = var.custom_cognito_domain
  type    = "A"
  zone_id = data.aws_route53_zone.shared_domain.zone_id

  alias {
    evaluate_target_health = false
    # ✅ FIXED ALIAS: Points directly to the CloudFront distribution ARN created by Cognito
    name                   = var.cognito_cloudfront_distribution_domain
    zone_id                = "Z2FDTNDATAQYW2" # Constant global AWS Zone ID for Cognito Custom Domains
  }
}