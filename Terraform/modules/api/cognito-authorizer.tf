# Create the Cognito Authorizer in API Gateway
resource "aws_api_gateway_authorizer" "cognito_auth" {
  name                              = "TodoCognitoAuthorizer"
  rest_api_id                       = aws_api_gateway_rest_api.zerefapi.id
  identity_source                   = "method.request.header.Authorization"
  provider_arns                     = [var.cognito_user_pool_arn]
  type                              = "COGNITO_USER_POOLS"
  authorizer_result_ttl_in_seconds  = 300
}