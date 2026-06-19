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

variable "api_validation_fqdns" {
  description = "FQDNs of the Route53 records created for API certificate validation"
  type    = list(string)
  default = []
}

variable "cognito_validation_fqdns" {
  description = "FQDNs of the Route53 records created for Cognito certificate validation"
  type    = list(string)
  default = []
}

variable "custom_cognito_domain" {
  description = "The custom domain name for Cognito"
  type        = string
}

variable "route53_validation_records" {
  description = "FQDNs of the Route53 records created for Cognito certificate validation"
  type        = list(string)
  default     = []  # Default value can be overridden
}
