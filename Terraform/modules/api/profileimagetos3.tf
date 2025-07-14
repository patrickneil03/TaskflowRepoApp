resource "aws_api_gateway_resource" "profileimagetos3" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  parent_id   = aws_api_gateway_rest_api.zerefapi.root_resource_id
  path_part   = "profileimagetos3"
}

resource "aws_api_gateway_method" "profileimagetos3_post" {
  rest_api_id   = aws_api_gateway_rest_api.zerefapi.id
  resource_id   = aws_api_gateway_resource.profileimagetos3.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "profileimagetos3_post" {
  rest_api_id             = aws_api_gateway_rest_api.zerefapi.id
  resource_id             = aws_api_gateway_resource.profileimagetos3.id
  http_method             = aws_api_gateway_method.profileimagetos3_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.profileimagetos3_function_name}/invocations"
}


resource "aws_api_gateway_method" "profileimagetos3_get" {
  rest_api_id   = aws_api_gateway_rest_api.zerefapi.id
  resource_id   = aws_api_gateway_resource.profileimagetos3.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "profileimagetos3_get" {
  rest_api_id             = aws_api_gateway_rest_api.zerefapi.id
  resource_id             = aws_api_gateway_resource.profileimagetos3.id
  http_method             = aws_api_gateway_method.profileimagetos3_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.profileimagetos3_function_name}/invocations"
}

# OPTIONS method without any backend integration (using MOCK integration)
resource "aws_api_gateway_method" "profileimagetos3_options" {
  rest_api_id   = aws_api_gateway_rest_api.zerefapi.id
  resource_id   = aws_api_gateway_resource.profileimagetos3.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "profileimagetos3_options" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.profileimagetos3.id
  http_method = aws_api_gateway_method.profileimagetos3_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "profileimagetos3_post_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.profileimagetos3.id
  http_method = aws_api_gateway_method.profileimagetos3_post.http_method
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

resource "aws_api_gateway_method_response" "profileimagetos3_get_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.profileimagetos3.id
  http_method = aws_api_gateway_method.profileimagetos3_get.http_method
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

resource "aws_api_gateway_method_response" "profileimagetos3_options_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.profileimagetos3.id
  http_method = aws_api_gateway_method.profileimagetos3_options.http_method
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

resource "aws_api_gateway_integration_response" "profileimagetos3_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.profileimagetos3.id
  http_method = aws_api_gateway_method.profileimagetos3_options.http_method
  status_code = aws_api_gateway_method_response.profileimagetos3_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
