variable "aws_cognito_user_pool_name" {
  description = "The name of the Cognito user pool"
  type        = string
  default     = "my-todolist-user-pool"
  
}

variable "aws_cognito_user_pool_client_name" {
  description = "The name of the Cognito user pool client"
  type        = string
  default     = "MytodoListweb"
  
}

variable "google_client_id" {
  description = "The client ID for Google authentication"
  type        = string
  sensitive = true
}

variable "google_client_secret" {
  description = "The client secret for Google authentication"
  type        = string
  sensitive = true
  
}

variable "facebook_app_id" {
  description = "The app ID for Facebook authentication"
  type        = string
  sensitive = true
}


variable "facebook_client_secret" {
  description = "The client secret for Facebook authentication"
  type        = string
  sensitive = true
  
}

variable "custom_cognito_domain" {
  description = "The domain for the Cognito user pool"
  type        = string
}

variable "region" {
  description = "The AWS region where the Cognito resources will be created"
  type        = string
  default     = "ap-southeast-1"
  
}

variable "uploadimagetos3_role_arn" {
  description = "The ARN of the Upload Image to S3 Role"
  type        = string
  
}

variable "cognito_cert_validation_arn" {
  description = "The ARN of the ACM certificate validation resource for Cognito"
  type        = string

}

variable "cognito_validation_dependency" {
  description = "The dependency for the Cognito certificate validation"
  type        = string
}

variable "route53_domain_name" {
  description = "The main domain name managed in Route 53"
  type        = string
}