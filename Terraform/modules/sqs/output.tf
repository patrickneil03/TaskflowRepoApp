output "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.todo_queue.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.todo_queue.id
}


output "notification_sqs_arn" {
  description = "ARN of the Notification SQS queue"
  value = aws_sqs_queue.notification_queue.arn
}

output "notification_sqs_url" {
  value = aws_sqs_queue.notification_queue.id
}

output "notification_dlq_arn" {
  description = "ARN of the Notification Dead Letter Queue"
  value       = aws_sqs_queue.notification_dlq.arn

}