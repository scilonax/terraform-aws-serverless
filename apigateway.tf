resource "aws_api_gateway_rest_api" "apis" {
  count = length(var.apis)
  name  = "${var.domain}-${var.apis[count.index].version}"
  body  = var.apis[count.index].swagger
}

resource "aws_api_gateway_deployment" "green_versions" {
  count       = length(var.apis)
  rest_api_id = aws_api_gateway_rest_api.apis[count.index].id
  stage_name  = "green"
  variables = {
    deploy_number = var.apis[count.index].green_deploy_count
  }
}

resource "aws_api_gateway_deployment" "blue_versions" {
  count       = length(var.apis)
  rest_api_id = aws_api_gateway_rest_api.apis[count.index].id
  stage_name  = "blue"
  variables = {
    deploy_number = var.apis[count.index].blue_deploy_count
  }
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name              = "api.${var.domain}"
  regional_certificate_arn = var.acm_certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "api" {
  name    = aws_api_gateway_domain_name.api.domain_name
  type    = "A"
  zone_id = var.route53_zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.api.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api.regional_zone_id
  }
}

resource "aws_api_gateway_base_path_mapping" "versions" {
  count       = length(var.apis)
  api_id      = aws_api_gateway_rest_api.apis[count.index].id
  stage_name  = var.apis[count.index].stage
  domain_name = aws_api_gateway_domain_name.api.domain_name
  base_path   = var.apis[count.index].version
  depends_on = [
    aws_api_gateway_deployment.blue_versions,
    aws_api_gateway_deployment.green_versions,
  ]
}
