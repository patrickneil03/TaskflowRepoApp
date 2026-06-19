output "domain_validation_options" {
  description = "DNS validation options for the main frontend certificate."
  value       = aws_acm_certificate.cert_baylenwebsite.domain_validation_options
}

output "domain_validation_options_api" {
  description = "DNS validation options for the API Gateway certificate."
  value       = aws_acm_certificate.api_cert.domain_validation_options
}

# 1. ADD THIS: Export validation options for your Cognito Custom Domain certificate
output "domain_validation_options_cognito" {
  description = "DNS validation options for the Cognito Custom Domain certificate."
  value       = aws_acm_certificate.cognito_cert.domain_validation_options
}

output "cert_baylenwebsite_arn" {
  description = "The ARN of the main frontend ACM certificate."
  value       = aws_acm_certificate.cert_baylenwebsite.arn
}

# 2. CLEANED: Removed the invalid depends_on block
output "api_cert_validation_arn" {
  description = "The ARN of the ACM certificate validation resource for the API."
  value       = aws_acm_certificate.api_cert.arn
}

# 3. CLEANED: Removed the invalid depends_on block
output "cognito_cert_validation_arn" {
  description = "The ARN of the ACM certificate validation resource for Cognito."
  value       = aws_acm_certificate.cognito_cert.arn
}
