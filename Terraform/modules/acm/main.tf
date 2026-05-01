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

//resource "aws_acm_certificate_validation" "cert_validation" {
 // certificate_arn         = aws_acm_certificate.cert_baylenwebsite.arn
 // validation_record_fqdns = var.cert_validation_fqdns
//}



