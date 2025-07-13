output "domain_validation_options" {
  description = "DNS validation options for the certificate."
  value       = aws_acm_certificate.cert_baylenwebsite.domain_validation_options
}

output "cert_baylenwebsite_arn" {
  description = "The ARN of the ACM certificate."
  value       = aws_acm_certificate.cert_baylenwebsite.arn
}

