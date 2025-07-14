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
    DISTRIBUTION_ID: "${var.cloudfront_distribution_id}"

phases:
  build:
    commands:
      - echo "🧹 Deleting all existing files in S3 bucket"
      - aws s3 rm s3://$TARGET_BUCKET --recursive

      - echo "🗺️ Listing local files"
      - ls -R .

      - echo "🔄 Syncing only frontend files (excluding Terraform, Git, README)"
      - >
        aws s3 sync . s3://$TARGET_BUCKET --delete
        --exclude "Terraform/*"
        --exclude "Terraform"
        --exclude ".git/*"
        --exclude ".git"
        --exclude "README.md"
        --exclude ".gitignore"
        --exclude ".gitattributes"

        - echo "🚀 Creating CloudFront invalidation"
      - >
        aws cloudfront create-invalidation
        --distribution-id $DISTRIBUTION_ID
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
