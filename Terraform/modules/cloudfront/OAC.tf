# Create Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-oac-${random_id.oac_suffix.hex}-${var.environment}"
  description                       = "Restrict S3 access to CloudFront only"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "profile_oac" {
  name                              = "s3-oac-profile-${random_id.oac_suffix.hex}-${var.environment}"
  description                       = "Restrict Profile S3 bucket access to CloudFront only"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}