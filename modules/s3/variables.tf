variable "aws_s3_bucket_name" {
  description = "The base name of the S3 bucket (a unique suffix will be appended)"
  type        = string
  default     = "baylentodolist"
}

variable "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution to restrict access to the S3 bucket"
  type        = string
  
}

variable "s3_bucket_name_profile" {
  description = "The base name of the S3 bucket (a unique suffix will be appended)"
  type        = string
  default     = "profiletodo"
}
