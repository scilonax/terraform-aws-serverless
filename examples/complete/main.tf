provider "aws" {
  region  = "us-east-1"
  profile = "scilonax_sandbox"
}

data "aws_route53_zone" "sandbox" {
  name = "sandbox.scilonax.com"
}

resource "aws_acm_certificate" "cert" {
  domain_name               = "aws-serverless.sandbox.scilonax.com"
  subject_alternative_names = ["*.aws-serverless.sandbox.scilonax.com"]
  validation_method = "EMAIL"
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = "${aws_acm_certificate.cert.arn}"
}

module "serverless_api" {
  source = "../../modules/api"
  acm_certificate_arn = aws_acm_certificate.cert.arn
  blue_deploy_count = 1
  green_deploy_count = 0
  current_stage = "blue"
  domain = "api.aws-serverless.sandbox.scilonax.com"
  name = "api.aws-serverless.sandbox.scilonax.com"
  path_version = "v1"
  swagger = data.template_file.api_swagger.rendered
  zone_id = data.aws_route53_zone.sandbox.id
}

module "serverless_lambda" {
  source = "../../modules/lambda"
  api_execution_arn = module.serverless_api.execution_arn
  bucket = module.serverless.lambda_bucket_id
  function_name = "post-ride"
  function_version = "0.0.0"
  handler = "exports.handler"
  layers_arn = []
  retention_in_days = 1
  runtime = "nodejs8.10"
  source_file = "exports.js"
}

resource "aws_dynamodb_table" "rides" {
  name         = "Rides"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "RideId"
  range_key    = ""

  attribute {
    name = "RideId"
    type = "S"
  }
}

module "serverless" {
  source                    = "../../"

  aws_profile               = "scilonax_sandbox"
  website_folder            = "website"
  route53_zone_id           = data.aws_route53_zone.sandbox.zone_id
  domain                    = "aws-serverless.sandbox.scilonax.com"
  cdn_origin_id             = "aws_serverless_sandbox_scilonax_com"
  acm_certificate_arn       = aws_acm_certificate.cert.arn
  lambda_role_name          = "iam_for_lambda"
  dynamodb_tables_arn       = [aws_dynamodb_table.rides.arn]
}

data "template_file" "api_swagger" {
  template = file("swagger.yaml")

  vars = {
    user_pool_arn        = module.serverless.cognito_user_pool_arn
    post_ride_invoke_arn = module.serverless_lambda.invoke_arn
  }
}

data "template_file" "config_js" {
  template = file("config.js")

  vars = {
    cognito_user_pool_id        = module.serverless.cognito_user_pool_id
    cognito_user_pool_client_id = module.serverless.cognito_user_pool_client_id
  }
}

resource "local_file" "config_js" {
  content  = data.template_file.config_js.rendered
  filename = "${path.module}/website/js/config.js"
}
