resource "aws_codebuild_project" "frontend_sync" {
  name          = "taskflow-frontend-sync"
  service_role  = var.cb_role_arn

  artifacts { 
    type = "CODEPIPELINE" 
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:6.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "TARGET_BUCKET"
      value = var.s3_bucket_my_bucket
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<BUILD_SPEC
version: 0.2

phases:
  build:
    commands:
      - echo "Syncing HTML and asset folders to S3 (deleting removed files)..."
      - |
        aws s3 sync . s3://$TARGET_BUCKET \
          --delete \
          --exclude "*" \
          --include "*.html" \
          --include "*.png" \
          --include "js/**" \
          --include "css/**" \
          --include "images/**"
BUILD_SPEC
  }
}
