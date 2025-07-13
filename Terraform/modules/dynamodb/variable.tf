variable "aws_dynamodb_table_name" {
  description = "The name of the DynamoDB table for todolist website"
  type        = string
  default     = "Todo"
  
}

variable "environment" {
  description = "The environment for the DynamoDB table"
  type        = string
  default     = "dev"
  
}

variable "region" {
  description = "The AWS region where the DynamoDB table will be deployed"
  type        = string
  default     = "ap-southeast-1"  # Change this to your desired region
  
}