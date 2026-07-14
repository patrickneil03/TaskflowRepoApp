# 1. Create the dedicated Dead Letter Queue (DLQ)
resource "aws_sqs_queue" "notification_dlq" {
  name                      = "taskflow-notification-dlq-dev"
  message_retention_seconds = 1209600 # 14 days retention (gives you plenty of time to debug)
  
  # FIX: Universal server-side encryption configuration
  kms_master_key_id         = "alias/aws/sqs"

  tags = {
    Environment = "dev"
    Project     = "TaskFlow"
    Purpose     = "DeadLetterQueue"
  }
}

# 2. Your updated main queue with the Redrive Policy attached
resource "aws_sqs_queue" "notification_queue" {
  name                      = "taskflow-notification-queue-dev"
  delay_seconds             = 0
  max_message_size          = 262144 # 256 KB (Maximum size allowed)
  message_retention_seconds = 345600 # 4 days retention
  receive_wait_time_seconds = 10     # Enables Long Polling to lower costs
  
  # FIX: Universal server-side encryption configuration
  kms_master_key_id         = "alias/aws/sqs"

  # Automatically catch and isolate poison pills
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_dlq.arn
    maxReceiveCount     = 3 # Message goes to DLQ on the 4th execution failure
  })

  tags = {
    Environment = "dev"
    Project     = "TaskFlow"
  }
}