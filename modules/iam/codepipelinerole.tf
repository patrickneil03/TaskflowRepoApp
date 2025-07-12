data "aws_caller_identity" "current" {}

resource "aws_iam_role" "cp_role" {
  name = "Taskflow-CodePipelineServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "codepipeline_policy" {
  name        = "Taskflow-CodePipeline-LimitedAccess"
  description = "Least-privilege policy for Taskflow CodePipeline"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. S3: artifacts bucket
      {
        Sid      = "ArtifactsBucketAccess"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject"]
        Resource = [
          var.s3_bucket_arn_artifact,
          "${var.s3_bucket_arn_artifact}/*"
        ]
      },

      # 2. S3: static-site bucket
      {
        Sid      = "SiteBucketAccess"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject"]
        Resource = [
          var.s3_bucket_arn_my_bucket,
          "${var.s3_bucket_arn_my_bucket}/*"
        ]
      },

      # 3. CodePipeline control actions
      {
        Sid      = "PipelineControl"
        Effect   = "Allow"
        Action   = [
          "codepipeline:PutJobSuccessResult",
          "codepipeline:PutJobFailureResult",
          "codepipeline:StartPipelineExecution",
          "codepipeline:GetPipelineState",
          "codepipeline:GetPipelineExecution",
          "codepipeline:ListPipelines",
          "codepipeline:ListPipelineExecutions"
        ]
        Resource = "*"
      },

      # 4. IAM PassRole
      {
        Sid      = "AllowPassRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.cp_role.arn
      },

      # 5. (Optional) CloudWatch Logs for pipeline
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cp_policy_attach" {
  role       = aws_iam_role.cp_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}




