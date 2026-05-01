output "domain_validation_options" {
  description = "DNS validation options for the certificate."
  value       = aws_acm_certificate.cert_baylenwebsite.domain_validation_options
}

output "domain_validation_options_api" {
  value = aws_acm_certificate.api_cert.domain_validation_options
}

output "cert_baylenwebsite_arn" {
  description = "The ARN of the ACM certificate."
  value       = aws_acm_certificate.cert_baylenwebsite.arn
}

output "api_cert_validation_arn" {
  description = "The arn of the ACM certificate validation resource."
  value       = aws_acm_certificate.api_cert.arn

  # This ensures the output isn't provided until the validation is finished
  depends_on = [aws_acm_certificate_validation.api_cert_validation]
}
