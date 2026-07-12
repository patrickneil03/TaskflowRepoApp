resource "aws_api_gateway_domain_name" "api" {
  domain_name              = var.custom_domain_name
  regional_certificate_arn = var.api_cert_validation_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# 🎯 THE UPDATE: Swap the legacy base path mapping for the HTTP API mapping
resource "aws_apigatewayv2_api_mapping" "mapping" {
  api_id      = aws_apigatewayv2_api.zerefapi.id
  domain_name = aws_api_gateway_domain_name.api.id
  stage       = aws_apigatewayv2_stage.prod.id
}