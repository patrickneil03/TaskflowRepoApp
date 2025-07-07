resource "aws_cloudwatch_event_rule" "trigger_deadline_check" {
  name                = "trigger-task-deadline-check"
  description         = "Triggers the deadline notifier Lambda every 30 minutes"
  schedule_expression = "rate(30 minutes)"  # Runs every 30 mins
}

resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.trigger_deadline_check.name
  target_id = "TodoDeadlineNotifier"
  arn       = var.notification_handler_arn # Your Lambda ARN
}