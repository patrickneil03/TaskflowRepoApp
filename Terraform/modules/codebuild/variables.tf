variable "s3_bucket_my_bucket" {
  description = "The name of the S3 bucket for taskflow static website."
  type        = string
  
}

variable "cb_role_arn" {
  description = "The ARN of the CodeBuild role."
  type        = string
  
}

variable "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution."
  type        = string
  
}
