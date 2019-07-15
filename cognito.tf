resource "aws_cognito_user_pool" "website_auth" {
  name = var.domain
}

resource "aws_cognito_user_pool_client" "website_auth_client" {
  name = var.domain
  user_pool_id = aws_cognito_user_pool.website_auth.id
}
