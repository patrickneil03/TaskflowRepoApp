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
      name             = "Sync_To_S3"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]

      configuration = {
        ProjectName = var.codebuild_project_name
      }
    }
  }
}
