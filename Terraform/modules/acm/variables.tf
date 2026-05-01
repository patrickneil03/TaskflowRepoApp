variable "route53_domain_name" {
  description = "The domain name for the Route 53 hosted zone"
  type        = string
}

variable "cert_validation_fqdns" {
    description = "FQDNs of the Route53 records created for certificate validation"
    type        = list(string)
    default     = []  # Default value can be overridden

}

variable "custom_domain_name" {
  description = "The custom domain name for the API"
  type        = string
}

variable "validation_fqdns" {
  description = "validation_fqdns for the ACM certificate validation"
  type    = list(string)
  default = []
}
