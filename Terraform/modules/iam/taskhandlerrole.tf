resource "aws_iam_role" "TaskHandlerRole" {
  name = "TaskHandlerRole"
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

resource "aws_iam_role_policy_attachment" "lambda_logs_taskhandler" {
  role       = aws_iam_role.TaskHandlerRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "crudinline_policy" {
  name = "CrudInlinePolicy"
  role = aws_iam_role.TaskHandlerRole.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:Query"
        ],
        Resource = "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.dynamodb_table_name}"

      }
    ]
  })
}