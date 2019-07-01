output "cognito_user_pool_arn" {
  value = "${aws_cognito_user_pool.website_auth.arn}"
}

output "cognito_user_pool_id" {
  value = "${aws_cognito_user_pool.website_auth.id}"
}

output "cognito_user_pool_client_id" {
  value = "${aws_cognito_user_pool_client.website_auth_client.id}"
}

output "cdn_id" {
  value = "${aws_cloudfront_distribution.website_cdn.id}"
}

output "lambda_invoke_arns" {
  value = "${aws_lambda_alias.lambdas.*.invoke_arn}"
}
