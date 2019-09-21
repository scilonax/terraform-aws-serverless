resource "aws_api_gateway_rest_api" "api" {
  name        = var.name
  body = var.swagger
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name              = var.domain
  regional_certificate_arn = var.acm_certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "api" {
  name    = aws_api_gateway_domain_name.api.domain_name
  type    = "A"
  zone_id = var.zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.api.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api.regional_zone_id
  }
}

resource "aws_api_gateway_deployment" "green_versions" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "green"
  variables = {
    deploy_number = var.green_deploy_count
  }
}

resource "aws_api_gateway_deployment" "blue_versions" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "blue"
  variables = {
    deploy_number = var.blue_deploy_count
  }
  depends_on = [aws_api_gateway_deployment.green_versions]
}

resource "aws_api_gateway_base_path_mapping" "versions" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = var.current_stage
  domain_name = aws_api_gateway_domain_name.api.domain_name
  base_path   = var.path_version
  depends_on = [
    aws_api_gateway_deployment.blue_versions,
    aws_api_gateway_deployment.green_versions,
  ]
}
