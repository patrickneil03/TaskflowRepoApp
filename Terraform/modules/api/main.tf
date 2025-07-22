resource "aws_api_gateway_rest_api" "zerefapi" {
  name        = "zerefapi"
  description = "API for registration with Lambda integration"
}


resource "aws_api_gateway_stage" "prod" {
  rest_api_id    = aws_api_gateway_rest_api.zerefapi.id
  deployment_id  = aws_api_gateway_deployment.zerefapi_deployment.id
  stage_name     = "prod"
}


#############################################
# 6. API Throtlling
#############################################
resource "aws_api_gateway_method_settings" "throttling" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  stage_name  = aws_api_gateway_stage.prod.stage_name

  method_path = "*/*"

  settings {
    throttling_rate_limit  = 5
    throttling_burst_limit = 10
    metrics_enabled        = true
    logging_level          = "OFF"
    data_trace_enabled     = false
  }
}

#############################################
# 7. Automatically Re-Deploy the API
#############################################

resource "aws_api_gateway_deployment" "zerefapi_deployment" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id

  triggers = {
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.token_post,
    aws_api_gateway_integration.token_options,
    aws_api_gateway_integration.taskhandler_post,
    aws_api_gateway_integration.taskhandler_get,
    aws_api_gateway_integration.taskhandler_options,
    aws_api_gateway_integration.taskhandler_id_delete,
    aws_api_gateway_integration.taskhandler_id_put,
    aws_api_gateway_integration.taskhandler_id_patch,
    aws_api_gateway_integration.taskhandler_id_options,
    aws_api_gateway_integration.profileimagetos3_post,
    aws_api_gateway_integration.profileimagetos3_get,
    aws_api_gateway_integration.profileimagetos3_options,
  ]
}



#############################################
# 8. Grant API Gateway Permission to Invoke Lambda
#############################################

resource "aws_lambda_permission" "allow_apigw_invoke_TokenHandler" {
  statement_id  = "AllowAPIGatewayInvokeTokenHandler"
  action        = "lambda:InvokeFunction"
  function_name = var.TokenHandlerCognito_function_name
  principal     = "apigateway.amazonaws.com"
  # The source ARN includes the API deployment stage and supports all methods
  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.zerefapi.id}/*/*"
}


resource "aws_lambda_permission" "allow_apigw_invoke_TaskHandler" {
  statement_id  = "AllowAPIGatewayInvokeTaskHandler"
  action        = "lambda:InvokeFunction"
  function_name = var.TaskHandler_function_name
  principal     = "apigateway.amazonaws.com"
  # The source ARN includes the API deployment stage and supports all methods
  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.zerefapi.id}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_invoke_profileimagetos3" {
  statement_id  = "AllowAPIGatewayInvokeprofileimagetos3"
  action        = "lambda:InvokeFunction"
  function_name = var.profileimagetos3_function_name
  principal     = "apigateway.amazonaws.com"
  # The source ARN includes the API deployment stage and supports all methods
  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.zerefapi.id}/*/*"
}