resource "aws_apigatewayv2_integration" "taskhandler" {
  api_id                 = aws_apigatewayv2_api.zerefapi.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.TaskHandler_function_name}/invocations"
  payload_format_version = "2.0"
}

# Protected POST /taskhandler
resource "aws_apigatewayv2_route" "taskhandler_post" {
  api_id             = aws_apigatewayv2_api.zerefapi.id
  route_key          = "POST /taskhandler"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  target             = "integrations/${aws_apigatewayv2_integration.taskhandler.id}"
}

# Protected GET /taskhandler
resource "aws_apigatewayv2_route" "taskhandler_get" {
  api_id             = aws_apigatewayv2_api.zerefapi.id
  route_key          = "GET /taskhandler"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  target             = "integrations/${aws_apigatewayv2_integration.taskhandler.id}"
}

# Protected routes parsing the explicit path parameters element block: /taskhandler/{id}
resource "aws_apigatewayv2_route" "taskhandler_id" {
  api_id             = aws_apigatewayv2_api.zerefapi.id
  route_key          = "ANY /taskhandler/{id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  target             = "integrations/${aws_apigatewayv2_integration.taskhandler.id}"
}