resource "aws_iam_role" "eventbridge_invoke_lambda" {
  name = "EventBridgeInvokeDeadlineNotifier"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_lambda_invoke" {
  role       = aws_iam_role.eventbridge_invoke_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"  # Or custom policy
}