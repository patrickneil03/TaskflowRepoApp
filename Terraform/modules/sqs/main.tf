resource "aws_sqs_queue" "todo_queue" {
  name                      = "taskflow-todo-queue-dev"
  delay_seconds             = 0
  max_message_size          = 262144 # 256 KB (Maximum size allowed)
  message_retention_seconds = 345600 # 4 days retention
  receive_wait_time_seconds = 10     # Enables Long Polling to lower costs

  tags = {
    Environment = "dev"
    Project     = "TaskFlow"
  }
}