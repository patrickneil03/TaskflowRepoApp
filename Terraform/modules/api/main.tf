# Create the High-Performance HTTP API resource
resource "aws_apigatewayv2_api" "zerefapi" {
  name          = "zerefapi"
  protocol_type = "HTTP"
  description   = "HTTP API for registration with Lambda integration"

  # Natively manages your CORS rules directly at the AWS edge layer
  cors_configuration {
    allow_origins = [var.complete_domain_name] # Or explicit: ["https://baylenweb-app.xyz"]
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_headers = ["content-type", "authorization", "x-amz-date", "x-api-key", "x-amz-security-token"]
    max_age       = 300
  }
}

# The single default stage that updates instantly on changes
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.zerefapi.id
  name        = "$default" # Merges routes into a clean base path mapping root
  auto_deploy = true

  # Throttling configured cleanly right inside the stage parameters block
  default_route_settings {
    throttling_burst_limit = 10
    throttling_rate_limit  = 5
  }
}

#############################################
# Grant API Gateway Permission to Invoke Lambda
#############################################

resource "aws_lambda_permission" "allow_apigw_invoke_TokenHandler" {
  statement_id  = "AllowAPIGatewayInvokeTokenHandler"
  action        = "lambda:InvokeFunction"
  function_name = var.TokenHandlerCognito_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.zerefapi.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_invoke_TaskHandler" {
  statement_id  = "AllowAPIGatewayInvokeTaskHandler"
  action        = "lambda:InvokeFunction"
  function_name = var.TaskHandler_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.zerefapi.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_invoke_profileimagetos3" {
  statement_id  = "AllowAPIGatewayInvoprofileimagetos3"
  action        = "lambda:InvokeFunction"
  function_name = var.profileimagetos3_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.zerefapi.execution_arn}/*/*"
}