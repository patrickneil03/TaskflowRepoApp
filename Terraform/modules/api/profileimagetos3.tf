# 1. Connect route path to the Profile Lambda handler integration
resource "aws_apigatewayv2_integration" "profileimagetos3" {
  api_id                 = aws_apigatewayv2_api.zerefapi.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.profileimagetos3_function_name}/invocations"
  payload_format_version = "2.0"
}

# 2.Expose the protected route rule endpoint
resource "aws_apigatewayv2_route" "profileimagetos3_post" {
  api_id             = aws_apigatewayv2_api.zerefapi.id
  route_key          = "POST /profileimagetos3"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  target             = "integrations/${aws_apigatewayv2_integration.profileimagetos3.id}"
}