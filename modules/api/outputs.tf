output "execution_arn" {
  value = aws_api_gateway_rest_api.api.execution_arn
}

output "domain_name" {
  value = aws_api_gateway_domain_name.api.domain_name
}

output "regional_domain_name" {
  value = aws_api_gateway_domain_name.api.regional_domain_name
}

output "regional_zone_id" {
  value = aws_api_gateway_domain_name.api.regional_zone_id
}
