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
    owner            = "AWS"
    provider         = "CodeStarSourceConnection"
    version          = "1"
    output_artifacts = ["SourceArtifact"]

    configuration = {
      ConnectionArn = var.codestar_connection_arn
      FullRepositoryId = "${var.github_owner}/${var.github_repo}"
      BranchName       = var.github_branch
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
      input_artifacts  = ["SourceArtifact"]

      configuration = {
        ProjectName = var.codebuild_project_name
      }
    }
  }
}
