# Generate a random suffix to ensure uniqueness for the OAC name
resource "random_id" "oac_suffix" {
  byte_length = 4
}
# Create the CloudFront distribution using the given S3 bucket as the origin.
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    # Use the dynamically provided S3 Bucket Regional Domain Name
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  # Add alternate domain names (CNAMEs) here.
  aliases = [
    var.route53_domain_name,   # Replace with your actual domain name, e.g., "www.baylenwebsite.xyz"
   
  ]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
  acm_certificate_arn      = var.cert_baylenwebsite_arn
  ssl_support_method       = "sni-only"
  minimum_protocol_version = "TLSv1.2_2021"
  }
}
