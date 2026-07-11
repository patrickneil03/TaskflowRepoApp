resource "aws_s3_bucket_policy" "allow_cloudfront_profile_access" {
  bucket = aws_s3_bucket.profile_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOACRead"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.profile_bucket.arn}/*"
        Condition = {
          StringEquals = {
            # Lock down access strictly to your specific CloudFront Distribution
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}