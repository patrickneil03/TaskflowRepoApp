resource "aws_iam_role" "UploadImageToS3" {
  name = "UploadImageToS3"
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

resource "aws_iam_role_policy_attachment" "lambda_logs_uploadimagetos3" {
  role       = aws_iam_role.UploadImageToS3.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "uploadimagetos3_policy" {
  name = "UploadImageToS3InlinePolicy"
  role = aws_iam_role.UploadImageToS3.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:HeadObject"
        ],
        Resource = "arn:aws:s3:::${var.s3_bucket_name_profile}/${var.s3_profile_folder}*"

      }
    ]
  })
}