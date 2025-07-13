resource "aws_iam_role" "CognitoAuthLambdaRole" {
  name = "CognitoAuthLambdaRole"
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

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.CognitoAuthLambdaRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "CognitoAuthLambdaInlinePolicy" {
  name = "CognitoAuthLambdaInlinePolicy"
  role = aws_iam_role.CognitoAuthLambdaRole.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "cognito-idp:SignUp",
          "cognito-idp:ResendConfirmationCode",
          "cognito-idp:InitiateAuth",
          "cognito-idp:ConfirmSignUp"
        ],
        Resource = var.cognito_user_pool_arn

      }
    ]
  })
}



resource "aws_iam_role_policy" "ForgotPasswordInlinePolicy" {
  name = "ForgotPasswordInlinePolicy"
  role = aws_iam_role.CognitoAuthLambdaRole.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "cognito-idp:ForgotPassword",
          "cognito-idp:ConfirmForgotPassword"
        ],
        Resource = var.cognito_user_pool_arn

      }
    ]
  })
}





