resource "aws_iam_role" "cb_role" {
  name = "Taskflow-CodeBuildServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cb_sync_policy" {
    name = "Taskflow-CodeBuildSyncPolicy"
  role = aws_iam_role.cb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = var.s3_bucket_arn_my_bucket
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.s3_bucket_arn_my_bucket}/*"
      }
    ]
  })
}
