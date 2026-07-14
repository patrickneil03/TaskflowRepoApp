# ==============================================================================
# 1. CORE API GATEWAY HTTP API (v2) DEFINITION
# ==============================================================================
resource "aws_apigatewayv2_api" "zerefapi" {
  name          = "zerefapi"
  protocol_type = "HTTP"
  description   = "HTTP API for registration with Lambda integration"

  # 🎯 Natively manages your CORS rules directly at the AWS edge layer
  cors_configuration {
    allow_credentials = true 
    
    allow_origins = [
      var.complete_domain_name 
    ] 
    
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    
    # ✅ FIXED: Swapped to standard Title-Case strings to satisfy browser preflight checklists
    allow_headers = [
      "Content-Type", 
      "Authorization", 
      "X-Amz-Date", 
      "X-Api-Key", 
      "X-Amz-Security-Token"
    ]
    
    max_age = 300
  }
}

# ==============================================================================
# 2. DEPLOYMENT STAGE DEFINITION
# ==============================================================================
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.zerefapi.id
  name        = "$default" # Merges routes into a clean base path mapping root
  auto_deploy = true

  # Throttling configured cleanly right inside the stage parameters block
  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }
}

# ==============================================================================
# 3. LAMBDA INVOKE PERMISSIONS GRANT
# ==============================================================================
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