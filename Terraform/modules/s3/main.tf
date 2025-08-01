# Retrieve AWS account details to incorporate the account-id into the bucket name.
data "aws_caller_identity" "current" {}

# Generate a random identifier to ensure uniqueness.
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "my_bucket" {
  # The final bucket name is now: <base_name>-<account_id>-<random_suffix>
  bucket = "${var.aws_s3_bucket_name}-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = var.aws_s3_bucket_name
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "profile_bucket" {
  # The final bucket name is now: <base_name>-<account_id>-<random_suffix>
  bucket = "${var.s3_bucket_name_profile}-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"
  
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
    allowed_origins = ["https://baylenwebsite.xyz"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}


resource "aws_s3_object" "profile_folder" {
  bucket  = aws_s3_bucket.profile_bucket.bucket   # reference the bucket name
  key     = "profile-pictures/"                           # note the trailing slash to indicate a folder
  content = ""                                    # empty content for a folder marker
  acl     = "private"                             # adjust ACL as needed
}



resource "aws_s3_bucket" "artifact" {
  bucket = "${var.aws_s3_bucket_name}-${data.aws_caller_identity.current.account_id}-artifacts-${random_id.bucket_suffix.hex}"
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




