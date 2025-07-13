resource "aws_scheduler_schedule" "deadline_check" {
  name        = "deadline-check-schedule"
  description = "Triggers Lambda every 12 hours to check task deadlines"

  flexible_time_window {
    mode = "OFF"  # Fixed schedule (not flexible)
  }

  # Runs every 30 minutes (cron: "*/30 * * * ? *" would also work)
  schedule_expression          = "rate(12 hours)"  
  schedule_expression_timezone = "Asia/Manila"  # Match your Lambda's timezone

  target {
    arn      = var.notification_handler_arn
    role_arn = var.eventbridge_invoke_lambda_role_arn  # See step 2
  }
}