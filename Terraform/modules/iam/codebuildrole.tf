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

resource "aws_iam_role_policy" "cb_logs_policy" {
  name = "AllowCodeBuildCloudWatchLogs"
  role = aws_iam_role.cb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current_cb.account_id}:log-group:/aws/codebuild/${var.codebuild_project_name}:*"
      }
    ]
  })
}

data "aws_caller_identity" "current_cb" {}



resource "aws_iam_role_policy" "cb_artifact_read" {
  name = "Taskflow-CodeBuildArtifactRead"
  role = aws_iam_role.cb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowListArtifactBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = var.s3_bucket_arn_artifact
      },
      {
        Sid      = "AllowGetArtifactObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "${var.s3_bucket_arn_artifact}/*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "cb_cloudfront_invalidation" {
  name = "Taskflow-CodeBuildCloudFrontInvalidation"
  role = aws_iam_role.cb_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudfront:CreateInvalidation"
        ],
        Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current_cb.account_id}:distribution/${var.cloudfront_distribution_id}"
      }
    ]
  })
}
