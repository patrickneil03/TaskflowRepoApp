variable "cognito_auth_role_arn" {
  description = "ARN of the Cognito Auth Lambda Role"
  type        = string
  
}

variable "taskhandler_role_arn" {
  description = "ARN of the TaskHandlerRole"
  type        = string
  
}

variable "uploadimagetos3_role_arn" {
  description = "ARN of the UploadImageToS3 role"
  type        = string
  
}

variable "s3_bucket_name_profile" {
  description = "The name of the s3 bucket for profile pictures"
  type        = string
  
}

variable "cognito_user_pool_id" {
  description = "User Pool ID for Cognito"
  type        = string
}

variable "cognito_client_id" {
  description = "Client ID for Cognito App Client"
  type        = string
  
}

variable "cognito_client_secret" {
  description = "Client Secret for Cognito App Client"
  type        = string
  
}

variable "notifications_role_arn" {
  description = "ARN of the NotificationsRole"
  type        = string
  
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for tasks"
  type        = string
  
}

variable "sender_email" {
  description = "Email address used to send notifications via SES"
  type        = string
}

variable "timezone" {
  description = "Timezone for scheduling notifications"
  type        = string
  default     = "Asia/Manila"  # Default to UTC if not specified
}
