variable "s3_bucket_regional_domain_name" {
  description = "The S3 Bucket Regional Domain Name to be used as CloudFront origin"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, test, prod) used to generate unique names"
  type        = string
  default     = "dev"
}

variable "cert_baylenwebsite_arn" {
  description = "The ARN of the ACM certificate to be used for CloudFront distribution"
  type        = string
  
}

variable "route53_domain_name" {
  description = "The domain name for the Route 53 hosted zone"
  type        = string
  default     = "baylenwebsite.xyz"  # Default value can be overridden
  
}

