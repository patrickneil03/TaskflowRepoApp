# 1. The Execution Role for the SQS Consumer
resource "aws_iam_role" "TaskConsumerRole" {
  name = "TaskConsumerRole-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Attach basic execution policy for CloudWatch Logging
resource "aws_iam_role_policy_attachment" "lambda_logs_taskconsumer" {
  role       = aws_iam_role.TaskConsumerRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 3. Inline policy allowing the consumer to read from SQS and put items into DynamoDB
resource "aws_iam_role_policy" "consumer_inline_policy" {
  name = "ConsumerInlinePolicy"
  role = aws_iam_role.TaskConsumerRole.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = var.sqs_queue_arn
      },
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:PutItem"
        ],
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}