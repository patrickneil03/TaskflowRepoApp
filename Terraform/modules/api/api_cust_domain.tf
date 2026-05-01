resource "aws_api_gateway_domain_name" "api" {
  domain_name              = var.custom_domain_name
  regional_certificate_arn = var.api_cert_validation_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  api_id      = aws_api_gateway_rest_api.zerefapi.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
}

