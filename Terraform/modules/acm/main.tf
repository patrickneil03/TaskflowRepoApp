terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}


resource "aws_acm_certificate" "cert_baylenwebsite" {
  domain_name       = var.route53_domain_name
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert_baylenwebsite.arn
  validation_record_fqdns = var.cert_validation_fqdns
}

