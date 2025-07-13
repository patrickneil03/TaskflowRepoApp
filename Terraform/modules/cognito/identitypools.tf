# Create a Cognito Identity Pool with only authenticated access allowed.
resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "ProfileIdentityPool"
  allow_unauthenticated_identities = false

  # Link the Cognito User Pool as an identity provider.
  cognito_identity_providers {
    client_id     = aws_cognito_user_pool_client.my_user_pool_client.id
    # The provider name format must be:
    # "cognito-idp.<region>.amazonaws.com/<user_pool_id>"
    # Ensure that <region> is replaced by your AWS region.
    provider_name = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.my_user_pool.id}"
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "identity_pool_roles" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool.id

  roles = {
    authenticated = var.uploadimagetos3_role_arn
  }
}