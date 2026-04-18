variable "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  type        = string
  
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

variable "route53_domain_name" {
  type = string
  description = "The domain name for my portfolio"
}



