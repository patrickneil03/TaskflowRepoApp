output "cognito_auth_role_arn" {
  value = aws_iam_role.CognitoAuthLambdaRole.arn
  description = "value of the Cognito Auth Lambda Role ARN"
}

output "taskhandler_role_arn" {
  value = aws_iam_role.TaskHandlerRole.arn
  description = "value of the TaskHandlerRole ARN"
}

output "uploadimagetos3_role_arn" {
  value = aws_iam_role.UploadImageToS3.arn
  description = "value of the UploadImageToS3 ARN"
}

output "notifications_role_arn" {
  value = aws_iam_role.NotificationsRole.arn
  description = "value of the NotificationsRole ARN"
  
}

output "eventbridge_invoke_lambda_role_arn" {
  value = aws_iam_role.eventbridge_invoke_lambda.arn
  description = "value of the EventBridge Invoke Lambda Role ARN"
  
}


output "cp_role_arn" {
  value = aws_iam_role.cp_role.arn
  description = "value of the CodePipeline Role ARN"
  
}

output "cb_role_arn" {
  value = aws_iam_role.cb_role.arn
  description = "value of the CodeBuild Role ARN"
  
}