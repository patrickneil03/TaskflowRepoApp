resource "aws_iam_role" "NotificationsRole" {
  name        = "DeadlineNotifierRole"
  description = "Permissions for Lambda to send deadline notifications via SES"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_notif_logs" {
  role       = aws_iam_role.NotificationsRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ses_notifications" {
  name = "SESNotificationsPolicy"
  role = aws_iam_role.NotificationsRole.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # DynamoDB Access
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Scan",          # To find tasks nearing deadlines
          "dynamodb:UpdateItem"      # To mark as notified
        ],
        Resource = [
          "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.dynamodb_table_name}",
          "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.dynamodb_table_name}/index/*"
        ]
      },
      
      # SES Email Permissions
      {
        Effect = "Allow",
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        Resource = "*"  # SES doesn't support resource-level permissions
      },
      
      # Cognito User Lookup
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:AdminGetUser"  # Only need this single action
        ],
        Resource = var.cognito_user_pool_arn
      }
    ]
  })
}