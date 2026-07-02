# Retrieve AWS account details to incorporate the account-id into the bucket name.
data "aws_caller_identity" "current" {}

# Generate a random identifier to ensure uniqueness.
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ==============================================================================
# 1. CORE TO-DO LIST DATA BUCKET
# ==============================================================================
resource "aws_s3_bucket" "my_bucket" {
  bucket        = "${var.aws_s3_bucket_name}-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"
  force_destroy = true
  tags = {
    Name        = var.aws_s3_bucket_name
    Environment = "Dev"
  }
}

# ==============================================================================
# 2. PROFILE BUCKET & CONFIGURATIONS
# ==============================================================================
resource "aws_s3_bucket" "profile_bucket" {
  bucket        = "${var.s3_bucket_name_profile}-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"
  force_destroy = true
  tags = {
    Name        = var.s3_bucket_name_profile
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_cors_configuration" "profile_bucket_cors" {
  bucket = aws_s3_bucket.profile_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET", "POST", "HEAD"]
    allowed_origins = ["https://${var.route53_domain_name}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_object" "profile_folder" {
  # ✅ FIXED: Changed .bucket to .id for modern best practices
  bucket       = aws_s3_bucket.profile_bucket.id   
  key          = "profile-pictures/"                
  content      = ""                                 
  
  # ✅ FIXED: Removed 'acl = "private"' to comply with Provider v5 specifications
}

# ==============================================================================
# 3. PIPELINE ARTIFACT BUCKET & CONFIGURATIONS
# ==============================================================================
resource "aws_s3_bucket" "artifact" {
  bucket        = "${var.aws_s3_bucket_name}-${data.aws_caller_identity.current.account_id}-artifacts-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  rule {
    id     = "expire-noncurrent"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}