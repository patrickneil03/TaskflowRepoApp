output "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.todo_queue.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.todo_queue.id
}