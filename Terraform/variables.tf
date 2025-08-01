variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-southeast-1"
  
}


variable "sender_email" {
  description = "Email address used to send notifications via SES"
  type        = string
  default = "noreply@baylenwebsite.xyz"
  
}

variable "google_client_secret" {
  description = "Google OAuth client secret (loaded from .auto.tfvars)"
  type        = string
  sensitive   = true
}

variable "facebook_client_secret" {
  description = "The client secret for Facebook authentication"
  type        = string
  sensitive = true
  
}

variable "google_client_id" {
  description = "The client ID for Google authentication"
  type        = string
  sensitive = true
}


variable "facebook_app_id" {
  description = "The app ID for Facebook authentication"
  type        = string
  sensitive = true
}


variable "github_owner" {
  description = "The owner of the GitHub repository"
  type        = string 
}

variable "github_repo" {
  description = "The name of the GitHub repository"
  type        = string
  
}

variable "github_branch" {
  description = "The branch of the GitHub repository to use"
  type        = string 
}

variable "codestar_connection_arn" {
  description = "ARN of the CodeStar connection for GitHub"
  type        = string
  sensitive   = true
}