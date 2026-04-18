variable "route53_domain_name" {
  description = "The domain name for the Route 53 hosted zone"
  type        = string
}

variable "cert_validation_fqdns" {
    description = "FQDNs of the Route53 records created for certificate validation"
    type        = list(string)
    default     = []  # Default value can be overridden
}

