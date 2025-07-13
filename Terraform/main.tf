terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
  
}

provider "aws" {
  region = var.region
}

# Provider alias for us-east-1 (required by CloudFront ACM certificates)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "s3" {
  source = "./modules/s3"
  cloudfront_distribution_arn = module.cloudfront.cloudfront_distribution_arn
}

module "cloudfront" {
  source = "./modules/cloudfront"
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  cert_baylenwebsite_arn = module.acm.cert_baylenwebsite_arn
  route53_domain_name = module.route53.route53_domain_name
  
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "cognito" {
  source = "./modules/cognito"
  uploadimagetos3_role_arn = module.iam.uploadimagetos3_role_arn
  google_client_secret = var.google_client_secret
  facebook_client_secret = var.facebook_client_secret
  google_client_id = var.google_client_id
  facebook_app_id = var.facebook_app_id
  
}

module "iam" {
  source = "./modules/iam"
  cognito_user_pool_arn = module.cognito.cognito_user_pool_arn
  dynamodb_table_name = module.dynamodb.dynamodb_table_name
  account_id = data.aws_caller_identity.current.account_id
  s3_bucket_name_profile = module.s3.s3_bucket_name_profile
  s3_profile_folder = module.s3.s3_profile_folder
  s3_bucket_arn_artifact = module.s3.s3_bucket_arn_artifact
  s3_bucket_arn_my_bucket = module.s3.s3_bucket_arn_my_bucket
  codebuild_project_arn = module.codebuild.codebuild_project_arn
  codebuild_project_name = module.codebuild.codebuild_project_name
  s3_bucket_name_artifact = module.s3.s3_bucket_name_artifact
 
}

module "lambda" {
  source = "./modules/lambda"
  cognito_auth_role_arn = module.iam.cognito_auth_role_arn
  taskhandler_role_arn = module.iam.taskhandler_role_arn
  uploadimagetos3_role_arn = module.iam.uploadimagetos3_role_arn
  s3_bucket_name_profile = module.s3.s3_bucket_name_profile
  cognito_user_pool_id = module.cognito.cognito_user_pool_id
  cognito_client_id = module.cognito.cognito_client_id
  cognito_client_secret = module.cognito.cognito_client_secret
  dynamodb_table_name = module.dynamodb.dynamodb_table_name
  notifications_role_arn = module.iam.notifications_role_arn
  sender_email = var.sender_email
}

data "aws_caller_identity" "current" {}

module "api" {
  source = "./modules/api"
  TokenHandlerCognito_function_name = module.lambda.TokenHandlerCognito_function_name
  TaskHandler_function_name = module.lambda.TaskHandler_function_name
  account_id = data.aws_caller_identity.current.account_id
  cognito_user_pool_arn = module.cognito.cognito_user_pool_arn
  profileimagetos3_function_name = module.lambda.profileimagetos3_function_name
}

module "route53" {
  source = "./modules/route53"
  cloudfront_distribution_domain_name = module.cloudfront.cloudfront_distribution_domain_name
  cloudfront_distribution_id = module.cloudfront.cloudfront_distribution_id
  domain_validation_options = module.acm.domain_validation_options
  ses_domain_identity_verification_token = module.ses.ses_domain_identity_verification_token
  
}

module "acm" {
  source = "./modules/acm"   # Your ACM module source
  route53_domain_name = module.route53.route53_domain_name
  cert_validation_fqdns = module.route53.cert_validation_fqdns
  providers = {
    aws = aws.us_east_1   # This override forces all resources in the ACM module to use us-east-1.
  }
  
}

module "eventbridge" {
  source = "./modules/eventbridge"
  notification_handler_arn = module.lambda.notification_handler_arn
  eventbridge_invoke_lambda_role_arn = module.iam.eventbridge_invoke_lambda_role_arn
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
  notification_handler_arn = module.lambda.notification_handler_arn
}

module "ses" {
  source = "./modules/ses"
  
}

module "codepipeline" {
  source = "./modules/codepipeline"
  github_owner = var.github_owner
  github_repo = var.github_repo
  github_branch = var.github_branch
  github_oauth_token = var.github_oauth_token
  cp_role_arn = module.iam.cp_role_arn
  s3_bucket_arn_artifact = module.s3.s3_bucket_arn_artifact
  s3_bucket_name_artifact = module.s3.s3_bucket_name_artifact
  s3_bucket_my_bucket = module.s3.s3_bucket_my_bucket
  codebuild_project_name = module.codebuild.codebuild_project_name
}


module "codebuild" {
  source = "./modules/codebuild"
  s3_bucket_my_bucket = module.s3.s3_bucket_my_bucket
  cb_role_arn = module.iam.cb_role_arn
  
}