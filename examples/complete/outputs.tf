output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.website_auth.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.website_auth_client.id
}

output "cdn_id" {
  value = module.serverless.cdn_id
}

