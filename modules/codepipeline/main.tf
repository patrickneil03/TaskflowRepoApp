resource "aws_codepipeline" "taskflow" {
  name     = "taskflow-pipeline-${var.environment}"
  role_arn = var.cp_role_arn

  artifact_store {
    type     = "S3"
    location = var.s3_bucket_name_artifact
  }

stage {
  name = "Source"

  action {
    name             = "GitHub_Source"
    category         = "Source"
    owner            = "ThirdParty"
    provider         = "GitHub"
    version          = "1"
    output_artifacts = ["source_output"]

    configuration = {
      Owner                = var.github_owner
      Repo                 = var.github_repo
      Branch               = var.github_branch
      OAuthToken           = var.github_oauth_token
      PollForSourceChanges = "true"
    }
  }
}

  stage {
    name = "Deploy"

    action {
      name            = "S3_Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        BucketName = var.s3_bucket_my_bucket
        Extract    = "true"
      }
    }
  }
}
