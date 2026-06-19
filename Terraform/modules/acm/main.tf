terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
      # ADD THIS LINE HERE
      configuration_aliases = [ aws.us_east_1 ]
    }
  }
}


resource "aws_acm_certificate" "cert_baylenwebsite" {
  provider          = aws.us_east_1
  domain_name       = var.route53_domain_name
  validation_method = "DNS"
}

# --- COGNITO CERTIFICATE (Must be us-east-1) ---
resource "aws_acm_certificate" "cognito_cert" {
  provider          = aws.us_east_1
  domain_name       = var.custom_cognito_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cognito_cert_validation" {
  provider                = aws.us_east_1 
  certificate_arn         = aws_acm_certificate.cognito_cert.arn
  validation_record_fqdns = var.cognito_validation_fqdns
}


