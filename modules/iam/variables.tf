variable "cognito_user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  type        = string
  
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table for TodoList website"
  type        = string
  default     = "Todo"  # Change this to your desired DynamoDB table name
  
}

variable "region" {
  description = "The AWS region where the IAM resources will be deployed"
  type        = string
  default     = "ap-southeast-1"  # Change this to your desired region
  
}

variable "account_id" {
  description = "The AWS account ID where the IAM resources will be deployed"
  type        = string
  
}

variable "s3_bucket_name_profile" {
  description = "The base name of the S3 bucket for profile pictures (a unique suffix will be appended)"
  type        = string
}

variable "s3_profile_folder" {
  description = "The S3 folder for profile pictures"
  type        = string
  default     = "profile-pictures/"  # Change this to your desired S3 folder name
  
}
