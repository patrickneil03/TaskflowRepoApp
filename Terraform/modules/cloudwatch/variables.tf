variable "notification_handler_arn" {
  description = "ARN of the Lambda function that handles notifications"
  type        = string
  
}

variable "zerefapi_id" {
  description = "ID of the API Gateway"
  type        = string

}

variable "api_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string

}

variable "TaskHandler_function_name" {
  description = "Name of the TaskHandler Lambda function"
  type        = string

}

variable "profileimagetos3_function_name" {
  description = "Name of the ProfileImageToS3 Lambda function"
  type        = string

}

variable "TokenHandlerCognito_function_name" {
  description = "Name of the TokenHandlerCognito Lambda function"
  type        = string

}

variable "task_consumer_function_name" {
  description = "Name of the TaskConsumer Lambda function"
  type        = string

}

variable "notification_consumer_function_name" {
  description = "Name of the NotificationConsumer Lambda function"
  type        = string

}

variable "notification_handler_function_name" {
  description = "Name of the NotificationHandler Lambda function"
  type        = string

}