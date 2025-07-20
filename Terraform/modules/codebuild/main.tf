resource "aws_codebuild_project" "frontend_sync" {
  name         = "taskflow-frontend-sync"
  service_role = var.cb_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:6.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = false

    environment_variable {
      name  = "TARGET_BUCKET"
      value = var.s3_bucket_my_bucket
    }
  }

  source {
    type = "CODEPIPELINE"
buildspec = <<BUILD_SPEC
version: 0.2

env:
  variables:
    TARGET_BUCKET: "${var.s3_bucket_my_bucket}"
    CLOUDFRONT_DISTRIBUTION_ID: "${var.cloudfront_distribution_id}" # <-- Add this to your Terraform variables

phases:
  build:
    commands:
      - echo "🗺️ Listing local files"
      - ls -R .

      - echo "🔄 Syncing only frontend files (excluding Terraform, Git, README)"
      - >
        aws s3 sync . s3://$TARGET_BUCKET
        --exclude "Terraform/*"
        --exclude "Terraform"
        --exclude ".git/*"
        --exclude ".git"
        --exclude "README.md"
        --exclude ".gitignore"
        --exclude ".gitattributes"

      - echo "🚀 Invalidating CloudFront cache"
      - >
        aws cloudfront create-invalidation
        --distribution-id $CLOUDFRONT_DISTRIBUTION_ID
        --paths "/*"
BUILD_SPEC

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/taskflow-frontend-sync"
      stream_name = "sync-logs"
    }
  }
}
