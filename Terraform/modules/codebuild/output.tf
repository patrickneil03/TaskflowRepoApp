output "codebuild_project_name" {
  description = "The name of the CodeBuild project for syncing the frontend"
  value       = aws_codebuild_project.frontend_sync.name
  
}