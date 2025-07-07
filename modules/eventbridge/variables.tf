variable "notification_handler_arn" {
  description = "ARN of the Lambda function that handles notifications"
  type        = string
  
}

variable "eventbridge_invoke_lambda_role_arn" {
  description = "ARN of the IAM role that allows EventBridge to invoke the Lambda function"
  type        = string
  
}