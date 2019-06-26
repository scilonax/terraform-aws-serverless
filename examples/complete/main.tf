provider "aws" {
  region = "us-east-1"
  profile = "scilonax"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}

data "aws_route53_zone" "scilonax_com" {
  name = "scilonax.com"
}

data "aws_acm_certificate" "scilonax_com" {
  domain = "scilonax.com"
}

module "serverless" {
  source = "../../"
  route53_zone_id = "${data.aws_route53_zone.scilonax_com.zone_id}"
  api_swagger = "${data.template_file.api_swagger.rendered}"
  domain = "example.scilonax.com"
  cdn_origin_id = "example_scilonax_com"
  acm_certificate_arn = "${data.aws_acm_certificate.scilonax_com.arn}"
  dynamodb_tables = ["Rides"]
  dynamodb_table_hash_keys = ["RideId"]
  dynamodb_table_range_keys = [""]
  dynamodb_table_attributes = [
    [{
      name = "RideId"
      type = "S"
    }]
  ]
  lambdas         = ["post-ride"]
  lambda_handlers = ["exports.handler"]
  lambda_runtimes = ["nodejs8.10"]
  lambda_versions = ["0.0.0"]
  lambda_files    = ["exports.js"]
}

data "template_file" "api_swagger" {
  template = "${file("swagger.yaml")}"

  vars {
    user_pool_arn  = "${module.serverless.cognito_user_pool_arn}"
    post_ride_lambda_arn = "${element(module.serverless.lambda_invoke_arns, 0)}"
  }
}
