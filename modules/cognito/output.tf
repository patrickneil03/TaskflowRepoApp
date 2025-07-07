output "cognito_user_pool_arn" {
  value = aws_cognito_user_pool.my_user_pool.arn
  description = "The ARN of the Cognito User Pool"
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.my_user_pool.id
  description = "The ID of the Cognito User Pool"
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.my_user_pool_client.id
  description = "The ID of the Cognito App Client"
  
}

output "cognito_client_secret" {
  value = aws_cognito_user_pool_client.my_user_pool_client.client_secret
  description = "The secret of the Cognito App Client"
  
}