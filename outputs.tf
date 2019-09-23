output "cognito_user_pool_arn" {
  value = aws_cognito_user_pool.website_auth.arn
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.website_auth.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.website_auth_client.id
}

output "cdn_id" {
  value = aws_cloudfront_distribution.website_cdn.id
}

output "cdn_domain_name" {
  value = aws_cloudfront_distribution.website_cdn.domain_name
}

output "lambda_bucket_id" {
  value = aws_s3_bucket.lambdas.id
}