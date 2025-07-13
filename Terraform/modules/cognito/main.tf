resource "aws_cognito_user_pool" "my_user_pool" {
  name                     = "my-todolist-user-pool"
  auto_verified_attributes = ["email"]

  // By not setting username_attributes with email, the pool uses username for sign-in.
  username_attributes = []

  // Explicit schema block to mark email as required.
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false  // Change to true if symbol requirement is desired.
  }

  tags = {
    Environment = "dev"
    Project     = "cognito-demo"
  }
}

resource "aws_cognito_user_pool_client" "my_user_pool_client" {
  name         = var.aws_cognito_user_pool_client_name
  user_pool_id = aws_cognito_user_pool.my_user_pool.id
  refresh_token_validity = 30
  generate_secret = true

  // Set the allowed OAuth flows and scopes.
  allowed_oauth_flows       = ["code"]
  allowed_oauth_scopes      = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true
  callback_urls  = ["http://localhost:8000/dashboard.html"]
  logout_urls    = ["http://localhost:8000"]

   supported_identity_providers = ["COGNITO", "Facebook", "Google"]

  # Explicit auth flows are included to support username/password login.
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
  
}

 resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.my_user_pool.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    client_id        = var.google_client_id
    client_secret    = var.google_client_secret
    authorize_scopes = "email openid profile"
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
    email_verified = "email_verified"
  }
 }

 resource "aws_cognito_identity_provider" "facebook" {
  user_pool_id  = aws_cognito_user_pool.my_user_pool.id
  provider_name = "Facebook"
  provider_type = "Facebook"

  provider_details = {
    client_id        = var.facebook_app_id
    client_secret    = var.facebook_client_secret
    authorize_scopes = "email public_profile"
  }

  attribute_mapping = {
    email    = "email"
    username = "id"
    
  }
}

resource "aws_cognito_user_pool_domain" "cognito_domain" {
  # Replace with your chosen unique domain prefix.
  domain       = var.MytodoListweb_cognito_domain
  user_pool_id = aws_cognito_user_pool.my_user_pool.id
}

