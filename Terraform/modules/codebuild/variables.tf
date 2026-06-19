variable "s3_bucket_my_bucket" {
  description = "The name of the S3 bucket for taskflow static website."
  type        = string
  
}

variable "cb_role_arn" {
  description = "The ARN of the CodeBuild role."
  type        = string
  
}

variable "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution."
  type        = string
  
}

variable "cognito_client_id" {
  description = "The ID of the Cognito User Pool Client."
  type        = string
  
}

variable "custom_cognito_domain" {
  description = "The custom domain name for the Cognito User Pool."
  type        = string
  
}

variable "identity_pool_id" {
  description = "The ID of the Cognito Identity Pool."
  type        = string
}

variable "user_pool_id" {
  description = "The ID of the Cognito User Pool."
  type        = string
}