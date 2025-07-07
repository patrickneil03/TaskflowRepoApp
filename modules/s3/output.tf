output "website_endpoint" {
  description = "The website endpoint URL"
  value       = aws_s3_bucket_website_configuration.static_website_config.website_endpoint
}

output "website_url" {
  description = "The full URL to access the static website"
  value       = "http://${aws_s3_bucket_website_configuration.static_website_config.website_endpoint}"
}


output "bucket_regional_domain_name" {
  value = aws_s3_bucket.my_bucket.bucket_regional_domain_name
}

output "bucket_id" {
  description = "The bucket ID."
  value       = aws_s3_bucket.my_bucket.id
}

output "s3_bucket_name_profile" {
  description = "The name of the S3 bucket for profile pictures."
  value       = aws_s3_bucket.profile_bucket.bucket
  
}

output "s3_profile_folder" {
  description = "The S3 folder for profile pictures."
  value       = aws_s3_object.profile_folder.key
  depends_on = [aws_s3_object.profile_folder]
  
}