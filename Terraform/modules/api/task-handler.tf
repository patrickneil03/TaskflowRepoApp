resource "aws_api_gateway_resource" "taskhandler" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  parent_id   = aws_api_gateway_rest_api.zerefapi.root_resource_id
  path_part   = "taskhandler"
}

resource "aws_api_gateway_method" "taskhandler_post" {
  rest_api_id   = aws_api_gateway_rest_api.zerefapi.id
  resource_id   = aws_api_gateway_resource.taskhandler.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id
  
  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_method" "taskhandler_get" {
  rest_api_id   = aws_api_gateway_rest_api.zerefapi.id
  resource_id   = aws_api_gateway_resource.taskhandler.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "taskhandler_post" {
  rest_api_id             = aws_api_gateway_rest_api.zerefapi.id
  resource_id             = aws_api_gateway_resource.taskhandler.id
  http_method             = aws_api_gateway_method.taskhandler_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.TaskHandler_function_name}/invocations"
}

resource "aws_api_gateway_integration" "taskhandler_get" {
  rest_api_id             = aws_api_gateway_rest_api.zerefapi.id
  resource_id             = aws_api_gateway_resource.taskhandler.id
  http_method             = aws_api_gateway_method.taskhandler_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.TaskHandler_function_name}/invocations"
}

# OPTIONS method without any backend integration (using MOCK integration)
resource "aws_api_gateway_method" "taskhandler_options" {
  rest_api_id   = aws_api_gateway_rest_api.zerefapi.id
  resource_id   = aws_api_gateway_resource.taskhandler.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "taskhandler_options" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.taskhandler.id
  http_method = aws_api_gateway_method.taskhandler_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}


#############################################
# 5. OPTIONS Method Response for CORS
#############################################

resource "aws_api_gateway_method_response" "taskhandler_post_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.taskhandler.id
  http_method = aws_api_gateway_method.taskhandler_post.http_method
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

resource "aws_api_gateway_method_response" "taskhandler_get_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.taskhandler.id
  http_method = aws_api_gateway_method.taskhandler_get.http_method
  status_code = "200"

  # Specifies that the response should carry the Access-Control-Allow-Origin header.
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }

  # Uses the built-in "Empty" model for application/json responses.
  response_models = {
    "application/json" = "Empty"
  }
}


#############################################
# 5. OPTIONS Method Response for CORS
#############################################

resource "aws_api_gateway_method_response" "taskhandler_options_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.taskhandler.id
  http_method = aws_api_gateway_method.taskhandler_options.http_method
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

resource "aws_api_gateway_integration_response" "taskhandler_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.taskhandler.id
  http_method = aws_api_gateway_method.taskhandler_options.http_method
  status_code = aws_api_gateway_method_response.taskhandler_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}


#############################################
# Create nested resource: /taskhandler/{id}
#############################################

resource "aws_api_gateway_resource" "taskhandler_id" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  parent_id   = aws_api_gateway_resource.taskhandler.id
  path_part   = "{id}"
}

#############################################
# DELETE method for /taskhandler/{id}
#############################################

resource "aws_api_gateway_method" "taskhandler_id_delete" {
  rest_api_id   = aws_api_gateway_rest_api.zerefapi.id
  resource_id   = aws_api_gateway_resource.taskhandler_id.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}


resource "aws_api_gateway_integration" "taskhandler_id_delete" {
  rest_api_id             = aws_api_gateway_rest_api.zerefapi.id
  resource_id             = aws_api_gateway_resource.taskhandler_id.id
  http_method             = aws_api_gateway_method.taskhandler_id_delete.http_method
  integration_http_method = "POST" // AWS Lambda proxy integrations typically use POST
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.TaskHandler_function_name}/invocations"
}


#############################################
# PUT method for /taskhandler/{id}
#############################################

resource "aws_api_gateway_method" "taskhandler_id_put" {
  rest_api_id   = aws_api_gateway_rest_api.zerefapi.id
  resource_id   = aws_api_gateway_resource.taskhandler_id.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "taskhandler_id_put" {
  rest_api_id             = aws_api_gateway_rest_api.zerefapi.id
  resource_id             = aws_api_gateway_resource.taskhandler_id.id
  http_method             = aws_api_gateway_method.taskhandler_id_put.http_method
  integration_http_method = "POST" // AWS Lambda proxy integrations typically use POST
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.TaskHandler_function_name}/invocations"
}


#############################################
# PATCH method for /taskhandler/{id}
#############################################
resource "aws_api_gateway_method" "taskhandler_id_patch" {
  rest_api_id   = aws_api_gateway_rest_api.zerefapi.id
  resource_id   = aws_api_gateway_resource.taskhandler_id.id
  http_method   = "PATCH"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}


resource "aws_api_gateway_integration" "taskhandler_id_patch" {
  rest_api_id             = aws_api_gateway_rest_api.zerefapi.id
  resource_id             = aws_api_gateway_resource.taskhandler_id.id
  http_method             = aws_api_gateway_method.taskhandler_id_patch.http_method
  integration_http_method = "POST" // AWS Lambda proxy integrations typically use POST
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.TaskHandler_function_name}/invocations"
}


#############################################
# OPTIONS method for /taskhandler/{id} (for CORS)
#############################################

resource "aws_api_gateway_method" "taskhandler_id_options" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.taskhandler_id.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "taskhandler_id_options" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.taskhandler_id.id
  http_method = aws_api_gateway_method.taskhandler_id_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

#############################################
# OPTIONS Method Response for CORS on /taskhandler/{id}
#############################################

resource "aws_api_gateway_method_response" "taskhandler_id_options_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.taskhandler_id.id
  http_method = aws_api_gateway_method.taskhandler_id_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "taskhandler_id_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.zerefapi.id
  resource_id = aws_api_gateway_resource.taskhandler_id.id
  http_method = aws_api_gateway_method.taskhandler_id_options.http_method
  status_code = aws_api_gateway_method_response.taskhandler_id_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,DELETE,PUT,PATCH'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}