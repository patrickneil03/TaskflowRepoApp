variable "cloudfront_distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  type        = string
  
}

variable "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  type        = string
  
}

variable "route53_domain_name" {
  description = "The domain name for the Route 53 hosted zone"
  type        = string
  default     = "baylenwebsite.xyz"  # Default value can be overridden
  
}

variable "cloudfront_distribution_hosted_zone_id" {
  description = "The CloudFront hosted zone ID (always Z2FDTNDATAQYW2)"
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

variable "domain_validation_options" {
  description = "DNS validation options for the ACM certificate"
  type        = list(object({
    domain_name          = string
    resource_record_name = string
    resource_record_type = string
    resource_record_value = string
  }))
  default     = []
  
}


variable "ses_domain_identity_verification_token" {
  description = "verification token fir ses domain"
}



