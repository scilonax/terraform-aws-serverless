output "cognito_user_pool_id" {
  value = "${module.serverless.cognito_user_pool_id}"
}

output "cognito_user_pool_client_id" {
  value = "${module.serverless.cognito_user_pool_client_id}"
}

output "aws_api_gateway_prod_invoke_url" {
  value = "${module.serverless.aws_api_gateway_prod_invoke_url}"
}

output "cdn_id" {
  value = "${module.serverless.cdn_id}"
}
