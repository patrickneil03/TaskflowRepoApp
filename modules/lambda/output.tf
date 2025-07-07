
output "TokenHandlerCognito_function_name" {
  value = aws_lambda_function.TokenHandlerCognito.function_name
  
}

output "TaskHandler_function_name" {
  value = aws_lambda_function.TaskHandler.function_name
  
}

output "profileimagetos3_function_name" {
  value = aws_lambda_function.ProfileImageToS3.function_name
  
}

output "notification_handler_arn" {
  value = aws_lambda_function.NotificationHandler.arn
  
}