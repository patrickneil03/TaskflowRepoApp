resource "aws_ses_domain_identity" "baylen" {
  domain = var.route53_domain_name
}


# Verify specific email addresses (for testing)
resource "aws_ses_email_identity" "noreply_identity" {
  email = var.ses_email_address
}
