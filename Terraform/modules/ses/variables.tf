variable "route53_domain_name" {
  description = "The domain name managed in Route 53 for SES verification"
  type        = string
}

variable "ses_email_address" {
  description = "The email address to be verified in SES"
  type        = string
}