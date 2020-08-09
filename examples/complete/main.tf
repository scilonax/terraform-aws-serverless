provider "aws" {
  region  = "us-east-1"
  profile = "scilonax_sandbox"
}

provider "aws" {
  region  = "us-east-1"
  profile = "scilonax"
  alias   = "root"
}

data "aws_route53_zone" "scilonax" {
  name     = "scilonax.com"
  provider = aws.root
}

resource "aws_acm_certificate" "cert" {
  domain_name               = "aws-serverless.sandbox.scilonax.com"
  subject_alternative_names = ["*.aws-serverless.sandbox.scilonax.com"]
  validation_method         = "EMAIL"
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
}

module "serverless_api" {
  source              = "../../modules/api"
  acm_certificate_arn = aws_acm_certificate.cert.arn
  blue_deploy_count   = 2
  green_deploy_count  = 1
  current_stage       = "blue"
  domain              = "api.aws-serverless.sandbox.scilonax.com"
  name                = "api.aws-serverless.sandbox.scilonax.com"
  path_version        = "v1"
  swagger             = data.template_file.api_swagger.rendered
}

module "serverless_api_domain" {
  providers = {
    aws = aws.root
  }
  source               = "../../modules/api_route53"
  zone_id              = data.aws_route53_zone.scilonax.id
  domain_name          = module.serverless_api.domain_name
  regional_domain_name = module.serverless_api.regional_domain_name
  regional_zone_id     = module.serverless_api.regional_zone_id
}

module "serverless_lambda" {
  source            = "../../modules/lambda"
  api_execution_arn = module.serverless_api.execution_arn
  bucket            = module.serverless.lambda_bucket_id
  function_name     = "post-ride"
  function_version  = "0.0.0"
  handler           = "exports.handler"
  retention_in_days = 1
  runtime           = "nodejs12.x"
  source_dir        = "exports"
}

resource "aws_dynamodb_table" "rides" {
  name         = "Rides"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "RideId"

  attribute {
    name = "RideId"
    type = "S"
  }
}

module "serverless" {
  source = "../../"

  aws_profile         = "scilonax_sandbox"
  website_folder      = "website"
  domain              = "aws-serverless.sandbox.scilonax.com"
  domain_aliases      = ["www.aws-serverless.sandbox.scilonax.com", "www1.aws-serverless.sandbox.scilonax.com"]
  cdn_origin_id       = "aws_serverless_sandbox_scilonax_com"
  acm_certificate_arn = aws_acm_certificate.cert.arn
  lambda_role_name    = "iam_for_lambda"
  dynamodb_tables_arn = [aws_dynamodb_table.rides.arn]
}

module "serverless_domain1" {
  providers = {
    aws = aws.root
  }
  source          = "../../modules/cloudfront_route53"
  domain          = "aws-serverless.sandbox.scilonax.com"
  cdn_domain_name = module.serverless.cdn_domain_name
  route53_zone_id = data.aws_route53_zone.scilonax.id
}

module "serverless_domain2" {
  providers = {
    aws = aws.root
  }
  source          = "../../modules/cloudfront_route53"
  domain          = "www.aws-serverless.sandbox.scilonax.com"
  cdn_domain_name = module.serverless.cdn_domain_name
  route53_zone_id = data.aws_route53_zone.scilonax.id
}

module "serverless_domain3" {
  providers = {
    aws = aws.root
  }
  source          = "../../modules/cloudfront_route53"
  domain          = "www1.aws-serverless.sandbox.scilonax.com"
  cdn_domain_name = module.serverless.cdn_domain_name
  route53_zone_id = data.aws_route53_zone.scilonax.id
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
