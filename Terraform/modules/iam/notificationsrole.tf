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
      # 🎯 DynamoDB Access (Optimized: Scan removed, Query added)
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Query",       # Required by Sweeper to search the GSI
          "dynamodb:UpdateItem"   # Required by Consumer to remove taskStatus
        ],
        Resource = [
          "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.dynamodb_table_name}",
          "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.dynamodb_table_name}/index/*"
        ]
      },
      
      # 📧 SES Email Permissions
      {
        Effect = "Allow",
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        Resource = "*" # SES does not support resource-level permissions
      },
      
      # 👥 Cognito User Lookup
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:AdminGetUser"
        ],
        Resource = var.cognito_user_pool_arn
      },

      # SQS Queue Operations (Covers both Sweeper & Consumer operations)
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",         # For Sweeper to send batches to the queue
          "sqs:ReceiveMessage",       # For Consumer to retrieve task alerts
          "sqs:DeleteMessage",        # For Consumer to acknowledge/clear processed tasks
          "sqs:GetQueueAttributes"    # Required by Lambda to monitor queue state
        ],
        Resource = [
          var.notification_sqs_arn,
          var.notification_dlq_arn     # Added DLQ ARN just in case
        ]
      }
    ]
  })
}