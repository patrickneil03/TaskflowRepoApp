resource "aws_codebuild_project" "frontend_sync" {
  name          = "taskflow-frontend-sync"
  service_role  = var.cb_role_arn

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
      value = trim(var.s3_bucket_my_bucket, "/")
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = trimspace(<<BUILD_SPEC
version: 0.2

phases:
  build:
    commands:
      - echo "🗺  Listing files in repo root for sanity check"
      - pwd
      - ls -alh
      - echo "🔄  Syncing repo → S3 (deleting any stale objects)…"
      - aws s3 sync . s3://$TARGET_BUCKET --delete --exclude "Terraform/*" --exclude "Terraform" --exclude ".git/*" --exclude ".git" --exclude "README.md" --exclude ".gitignore" --exclude ".gitattributes"
BUILD_SPEC
    )
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/taskflow-frontend-sync"
      stream_name = "sync-logs"
    }
  }
}
