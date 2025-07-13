output "codebuild_project_name" {
  description = "The name of the CodeBuild project for syncing the frontend"
  value       = aws_codebuild_project.frontend_sync.name
  
}

output "codebuild_project_arn" {
  description = "The ARN of the CodeBuild project for syncing the frontend"
  value       = aws_codebuild_project.frontend_sync.arn
  
}