resource "aws_codebuild_project" "frontend_sync" {
  name         = "taskflow-frontend-sync"
  service_role = var.cb_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:6.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = false

    environment_variable {
      name  = "TARGET_BUCKET"
      value = var.s3_bucket_my_bucket
    }

    environment_variable {
      name  = "COGNITO_CLIENT_ID"
      value = var.cognito_client_id
    }

    environment_variable {
      name  = "CUSTOM_COGNITO_DOMAIN"
      value = var.custom_cognito_domain
    }

    environment_variable {
      name  = "IDENTITY_POOL_ID"
      value = var.identity_pool_id
    }

    environment_variable {
      name  = "USER_POOL_ID"
      value = var.user_pool_id
    }

    # ✅ NEW: Domain-driven API and redirection routing configurations
    environment_variable {
      name  = "API_URL"
      value = "https://api.${var.custom_domain_name}/taskhandler"
    }

    environment_variable {
      name  = "TOKEN_EXCHANGE_URL"
      value = "https://api.${var.custom_domain_name}/token"
    }

    environment_variable {
      name  = "REDIRECT_URI"
      value = "https://${var.custom_domain_name}/dashboard.html"
    }

    environment_variable {
      name  = "LOGOUT_URI"
      value = "https://${var.custom_domain_name}"
    }

    environment_variable {
      name  = "PROFILE_API_URL"
      value = "https://api.${var.custom_domain_name}/profileimagetos3"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<BUILD_SPEC
version: 0.2

env:
  variables:
    TARGET_BUCKET: "${var.s3_bucket_my_bucket}"
    CLOUDFRONT_DISTRIBUTION_ID: "${var.cloudfront_distribution_id}"
    COGNITO_CLIENT_ID: "${var.cognito_client_id}"
    CUSTOM_COGNITO_DOMAIN: "${var.custom_cognito_domain}"
    IDENTITY_POOL_ID: "${var.identity_pool_id}"
    USER_POOL_ID: "${var.user_pool_id}"
    API_URL: "https://api.${var.custom_domain_name}/taskhandler"
    TOKEN_EXCHANGE_URL: "https://api.${var.custom_domain_name}/token"
    REDIRECT_URI: "https://${var.custom_domain_name}/dashboard.html"
    LOGOUT_URI: "https://${var.custom_domain_name}"
    PROFILE_API_URL: "https://api.${var.custom_domain_name}/profileimagetos3"

phases:
  build:
    commands:
      - echo "🗺️ Listing workspace local files"
      - ls -R .

      - echo "✏️ Injecting dynamic endpoints into index.html..."
      - sed -i "s/__CUSTOM_COGNITO_DOMAIN__/$CUSTOM_COGNITO_DOMAIN/g" index.html
      - sed -i "s/__COGNITO_CLIENT_ID__/$COGNITO_CLIENT_ID/g" index.html
      - sed -i "s|__REDIRECT_URI__|$REDIRECT_URI|g" index.html

      - echo "✏️ Injecting dynamic endpoints into js/app.js..."
      - sed -i "s/__CUSTOM_COGNITO_DOMAIN__/$CUSTOM_COGNITO_DOMAIN/g" js/app.js
      - sed -i "s/__COGNITO_CLIENT_ID__/$COGNITO_CLIENT_ID/g" js/app.js
      - sed -i "s|__API_URL__|$API_URL|g" js/app.js
      - sed -i "s|__TOKEN_EXCHANGE_URL__|$TOKEN_EXCHANGE_URL|g" js/app.js
      - sed -i "s|__REDIRECT_URI__|$REDIRECT_URI|g" js/app.js
      - sed -i "s|__LOGOUT_URI__|$LOGOUT_URI|g" js/app.js

      - echo "✏️ Injecting dynamic endpoints into js/profile.js..."
      - sed -i "s/__CUSTOM_COGNITO_DOMAIN__/$CUSTOM_COGNITO_DOMAIN/g" js/profile.js
      - sed -i "s/__COGNITO_CLIENT_ID__/$COGNITO_CLIENT_ID/g" js/profile.js
      - sed -i "s/__IDENTITY_POOL_ID__/$IDENTITY_POOL_ID/g" js/profile.js
      - sed -i "s/__USER_POOL_ID__/$USER_POOL_ID/g" js/profile.js
      - sed -i "s|__PROFILE_API_URL__|$PROFILE_API_URL|g" js/profile.js
      - sed -i "s|__LOGOUT_URI__|$LOGOUT_URI|g" js/profile.js

      - echo "🔄 Syncing only frontend files (excluding Terraform, Git, README)"
      - >
        aws s3 sync . s3://$TARGET_BUCKET
        --exclude "Terraform/*"
        --exclude "Terraform"
        --exclude ".git/*"
        --exclude ".git"
        --exclude "README.md"
        --exclude ".gitignore"
        --exclude ".gitattributes"

      - echo "🚀 Invalidating CloudFront cache"
      - >
        aws cloudfront create-invalidation
        --distribution-id $CLOUDFRONT_DISTRIBUTION_ID
        --paths "/*"
BUILD_SPEC
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/taskflow-frontend-sync"
      stream_name = "sync-logs"
    }
  }
}