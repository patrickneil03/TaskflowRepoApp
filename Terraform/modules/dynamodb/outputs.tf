output "dynamodb_table_name" {
  value       = var.aws_dynamodb_table_name
  description = "The name of the DynamoDB table for TodoList website"
  
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.todolist_dynamodb_table.arn
  description = "The ARN of the DynamoDB table for TodoList website"
}