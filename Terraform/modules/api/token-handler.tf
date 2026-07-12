resource "aws_apigatewayv2_integration" "token" {
  api_id                 = aws_apigatewayv2_api.zerefapi.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.TokenHandlerCognito_function_name}/invocations"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "token_post" {
  api_id    = aws_apigatewayv2_api.zerefapi.id
  route_key = "POST /token"
  target    = "integrations/${aws_apigatewayv2_integration.token.id}"
}