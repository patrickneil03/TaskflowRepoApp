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

variable "custom_domain_name" {
  type = string
  description = "The custom domain name for the API"
}


variable "regional_domain_name" {
  type = string
}

variable "regional_zone_id" {
  type = string
  description = "regional zone id for the API Gateway custom domain"
}