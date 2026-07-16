output "account_id" {
  value = var.account_id
}

output "current_account_id" {
  value = var.account_id
}

output "regional_domain_name" {
  value = aws_api_gateway_domain_name.api.regional_domain_name
}

output "regional_zone_id" {
  value = aws_api_gateway_domain_name.api.regional_zone_id
}

output "zerefapi_id" {
  value = aws_apigatewayv2_api.zerefapi.id
}

output "api_stage_name" {
  value = aws_apigatewayv2_stage.prod.name

}