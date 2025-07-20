variable "environment" {
  description = "The DEV environment for CodePipeline"
  type        = string
  default     = "Dev"
  
}

variable "github_owner" {
  type = string
  default = "patrickneil03"
}

variable "github_repo" {
  type = string
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "cp_role_arn" {
  description = "The ARN of the CodePipeline role"
  type        = string
}

variable "s3_bucket_arn_artifact" {
  description = "The ARN of the S3 bucket for artifacts"
  type        = string
  
}


variable "s3_bucket_name_artifact" {
  description = "The name of the S3 bucket for artifacts"
  type        = string
  
}

variable "s3_bucket_my_bucket" {
  description = "The name of the S3 bucket for taskflow static website"
  type        = string
  
}

variable "codebuild_project_name" {
  description = "The name of the CodeBuild project for syncing the frontend"
  type        = string
  
}

variable "codestar_connection_arn" {
  description = "ARN of the CodeStar connection for GitHub"
  type        = string
  sensitive   = true
  
}