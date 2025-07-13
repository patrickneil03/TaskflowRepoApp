variable "TokenHandlerCognito_function_name" {
  description = "The name of the Lambda function for TokenHandlerCognito"
  type        = string
  
}


variable "TaskHandler_function_name" {
  description = "The name of the Lambda function for TaskHandlerCognito"
  type        = string
  
}

variable "profileimagetos3_function_name" {
  description = "The name of the Lambda function for ProfileImageToS3"
  type        = string
  
}

variable "region" {
  description = "The AWS region where the API Gateway and Lambda function will be deployed"
  type        = string
  default     = "ap-southeast-1"  # Change this to your desired region
  
}

variable "account_id" {
  description = "The AWS account ID where the API Gateway and Lambda function will be deployed"
  type        = string
}

variable "api_name" {
  description = "The name of the API Gateway"
  default     = "zerefapi"  # Change this to your desired API name
  
}

variable "cognito_user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  type        = string
  default     = ""  # This should be set to the actual Cognito User Pool ARN when using the module
  
}
