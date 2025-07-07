resource "aws_api_gateway_resource" "token" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  parent_id   = aws_api_gateway_rest_api.zerefapi.root_resource_id
  path_part   = "token"
}

resource "aws_api_gateway_method" "token_post" {
  rest_api_id   = aws_api_gateway_rest_api.zerefapi.id
  resource_id   = aws_api_gateway_resource.token.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "token_post" {
  rest_api_id             = aws_api_gateway_rest_api.zerefapi.id
  resource_id             = aws_api_gateway_resource.token.id
  http_method             = aws_api_gateway_method.token_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.TokenHandlerCognito_function_name}/invocations"
}

# OPTIONS method without any backend integration (using MOCK integration)
resource "aws_api_gateway_method" "token_options" {
  rest_api_id   = aws_api_gateway_rest_api.zerefapi.id
  resource_id   = aws_api_gateway_resource.token.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "token_options" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.token_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}


#############################################
# 5. OPTIONS Method Response for CORS
#############################################

resource "aws_api_gateway_method_response" "token_post_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.token_post.http_method
  status_code = "200"

  # Specifies that the response should carry the Access-Control-Allow-Origin header.
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  # Uses the built-in "Empty" model for application/json responses.
  response_models = {
    "application/json" = "Empty"
  }
}


#############################################
# 5. OPTIONS Method Response for CORS
#############################################

resource "aws_api_gateway_method_response" "token_options_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.token_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "token_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.token_options.http_method
  status_code = aws_api_gateway_method_response.token_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}