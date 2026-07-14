
resource "aws_lambda_function" "TokenHandlerCognito" {
  filename         = "${path.module}/lambda-function/token-handler.zip"
  function_name    = "TokenHandlerCognito"
  role             = var.cognito_auth_role_arn
  handler          = "token-handler.lambda_handler"  
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/lambda-function/token-handler.zip")
  
  environment {
    variables = {
      CLIENT_ID             = var.cognito_client_id
      CLIENT_SECRET         = var.cognito_client_secret
      CUSTOM_COGNITO_DOMAIN = var.custom_cognito_domain
      REDIRECT_URI          = "https://${var.route53_domain_name}/dashboard.html"
      ALLOWED_ORIGIN = "https://${var.route53_domain_name}"
    }
  }
}

resource "aws_lambda_function" "TaskHandler" {
  filename         = "${path.module}/lambda-function/task-handler.zip"
  function_name    = "TaskHandler"
  role             = var.taskhandler_role_arn
  handler          = "task-handler.lambda_handler"  
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/lambda-function/task-handler.zip")
  environment {
    variables = {
      SQS_QUEUE_URL = var.sqs_queue_url
      ALLOWED_ORIGIN = "https://${var.route53_domain_name}"
    }
  }
}

resource "aws_lambda_function" "TaskConsumer" {
  filename         = "${path.module}/lambda-function/task-consumer.zip"
  function_name    = "TaskConsumer"
  role             = var.taskconsumer_role_arn # Attaches your newly built consumer role
  handler          = "task-consumer.lambda_handler"  
  runtime          = "python3.12"                      
  timeout          = 30                                
  source_code_hash = filebase64sha256("${path.module}/lambda-function/task-consumer.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }
}

# The Trigger Event that connects SQS to this Consumer Function
resource "aws_lambda_event_source_mapping" "sqs_to_lambda_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.TaskConsumer.arn
  batch_size       = 10   # Pulls up to 10 items at once from SQS for processing efficiency
  enabled          = true

  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_lambda_function" "NotificationHandler" {
  filename         = "${path.module}/lambda-function/notification-handler.zip"
  function_name    = "NotificationHandler"
  role             = var.notifications_role_arn # Ensure this IAM role has permission to Write to the SQS queue!
  handler          = "notification-handler.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/lambda-function/notification-handler.zip")

  environment {
    variables = {
      DYNAMODB_TABLE  = var.dynamodb_table_name
      SQS_QUEUE_URL   = var.notification_sqs_url
      TIMEZONE        = var.timezone
    }
  }
}



resource "aws_lambda_function" "notification_consumer" {
  filename         = "${path.module}/lambda-function/notification-consumer.zip"
  function_name    = "NotificationConsumer"
  role             = var.notifications_role_arn # Ensure this role can read SQS, query Cognito, and send via SES
  handler          = "notification-consumer.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/lambda-function/notification-consumer.zip")

  environment {
    variables = {
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
      DYNAMODB_TABLE       = var.dynamodb_table_name
      SES_SENDER_EMAIL     = var.sender_email
      TIMEZONE             = var.timezone
    }
  }
}

# This resource links the Queue to your Consumer Lambda, making it wake up automatically
resource "aws_lambda_event_source_mapping" "notification_queue_trigger" {
  event_source_arn = var.notification_sqs_arn
  function_name    = aws_lambda_function.notification_consumer.arn
  batch_size       = 10 # Process up to 10 email notification tasks concurrently
  
  # Crucial for returning batchItemFailures properly:
  function_response_types = ["ReportBatchItemFailures"] 
}

resource "aws_lambda_function" "ProfileImageToS3" {
  filename         = "${path.module}/lambda-function/profileimagetos3.zip"
  function_name    = "ProfileImageToS3"
  role             = var.uploadimagetos3_role_arn
  handler          = "profileimagetos3.lambda_handler"  
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/lambda-function/profileimagetos3.zip")
  environment {
    variables = {
      PROFILE_BUCKET = var.s3_bucket_name_profile
      ALLOWED_ORIGIN = "https://${var.route53_domain_name}"
    }
  }
}