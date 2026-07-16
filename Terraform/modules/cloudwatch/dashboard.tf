resource "aws_cloudwatch_dashboard" "todo_dashboard" {
  dashboard_name = "TaskFlow-TodoApp-Metrics"

  dashboard_body = jsonencode({
    widgets = [
      # ==============================================================================
      # ROW 1: USER EXPERIENCE (HTTP API GATEWAY V2)
      # ==============================================================================
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            # Dynamically binds directly to your zerefapi ID and your $default stage
            [ "AWS/ApiGateway", "Latency", "ApiId", "${var.zerefapi_id}", "Stage", "${var.api_stage_name}", { "stat": "Average", "label": "Avg Latency" } ],
            [ "...", { "stat": "p99", "label": "p99 Latency (Worst Case)" } ]
          ]
          period  = 60
          region  = "ap-southeast-1"
          title   = "HTTP API Response Latency (ms)"
          view    = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            # Tracks HTTP-specific lowercase 4xx and 5xx errors for your API
            [ "AWS/ApiGateway", "4xx", "ApiId", "${var.zerefapi_id}", "Stage", "${var.api_stage_name}", { "stat": "Sum", "color": "#ff7f0e", "label": "Client Errors (4xx)" } ],
            [ "AWS/ApiGateway", "5xx", "ApiId", "${var.zerefapi_id}", "Stage", "${var.api_stage_name}", { "stat": "Sum", "color": "#d62728", "label": "Server Errors (5xx)" } ]
          ]
          period  = 60
          region  = "ap-southeast-1"
          title   = "HTTP API Error Rates"
          view    = "timeSeries"
          stacked = false
        }
      },

      # ==============================================================================
      # ROW 2: CORE INGESTION & USER ENGINE (INBOUND FUNCTIONS)
      # ==============================================================================
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            # 🎯 Dynamically tracks invocations of your edge APIs and Task Handlers
            [ "AWS/Lambda", "Invocations", "FunctionName", "${var.TokenHandlerCognito_function_name}", { "stat": "Sum", "label": "TokenHandler Runs" } ],
            [ "...", "${var.TaskHandler_function_name}", { "stat": "Sum", "label": "TaskHandler (Inbound) Runs" } ],
            [ "...", "${var.profileimagetos3_function_name}", { "stat": "Sum", "label": "Profile Image Handler Runs" } ]
          ]
          period  = 60
          region  = "ap-southeast-1"
          title   = "User Lambda Invocations"
          view    = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            # Tracks execution errors for the edge handlers
            [ "AWS/Lambda", "Errors", "FunctionName", "${var.TokenHandlerCognito_function_name}", { "stat": "Sum", "color": "#ff7f0e", "label": "TokenHandler Errors" } ],
            [ "...", "${var.TaskHandler_function_name}", { "stat": "Sum", "color": "#d62728", "label": "TaskHandler Errors" } ],
            [ "...", "${var.profileimagetos3_function_name}", { "stat": "Sum", "color": "#9467bd", "label": "Profile Image Errors" } ]
          ]
          period  = 60
          region  = "ap-southeast-1"
          title   = "User Lambda Execution Errors"
          view    = "timeSeries"
          stacked = false
        }
      },

      # ==============================================================================
      # ROW 3: BACKGROUND CONSUMERS & SCHEDULERS (WORKER ENGINE)
      # ==============================================================================
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            # Monitors the internal processing loops (Consumers & Cron Sweepers)
            [ "AWS/Lambda", "Invocations", "FunctionName", "${var.task_consumer_function_name}", { "stat": "Sum", "label": "TaskConsumer Runs" } ],
            [ "...", "${var.notification_handler_function_name}", { "stat": "Sum", "label": "Notification Sweeper Runs" } ],
            [ "...", "${var.notification_consumer_function_name}", { "stat": "Sum", "label": "NotificationConsumer Runs" } ]
          ]
          period  = 60
          region  = "ap-southeast-1"
          title   = "Worker Lambda Invocations"
          view    = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            # Tracks failures in your SQS consumer integrations and cron logic
            [ "AWS/Lambda", "Errors", "FunctionName", "${var.task_consumer_function_name}", { "stat": "Sum", "color": "#d62728", "label": "TaskConsumer Errors" } ],
            [ "...", "${var.notification_handler_function_name}", { "stat": "Sum", "color": "#1f77b4", "label": "Notification Sweeper Errors" } ],
            [ "...", "${var.notification_consumer_function_name}", { "stat": "Sum", "color": "#2ca02c", "label": "NotificationConsumer Errors" } ]
          ]
          period  = 60
          region  = "ap-southeast-1"
          title   = "Worker Lambda Execution Errors"
          view    = "timeSeries"
          stacked = false
        }
      }
    ]
  })
}