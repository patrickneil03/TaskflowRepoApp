resource "aws_ses_domain_identity" "baylen" {
  domain = "baylenwebsite.xyz"
}


# Verify specific email addresses (for testing)
resource "aws_ses_email_identity" "noreply_identity" {
  email = "patrickbaylen3@gmail.com"
}
