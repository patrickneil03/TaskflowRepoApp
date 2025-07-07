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

resource "aws_s3_object" "profile_folder" {
  bucket  = aws_s3_bucket.profile_bucket.bucket   # reference the bucket name
  key     = "profile-pictures/"                           # note the trailing slash to indicate a folder
  content = ""                                    # empty content for a folder marker
  acl     = "private"                             # adjust ACL as needed
}

