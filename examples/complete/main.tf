provider "aws" {
  region = "us-east-1"
  profile = "scilonax"
}

data "aws_route53_zone" "scilonax_com" {
  name = "scilonax.com"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "*.scilonax.com"
  validation_method = "DNS"
  subject_alternative_names = ["scilonax.com", "*.guiadev.scilonax.com"]
  
  lifecycle {
    create_before_destroy = true
  }
}

module "serverless" {
  source = "../../"
  aws_profile = "scilonax"
  website_folder = "website"
  route53_zone_id = "${data.aws_route53_zone.scilonax_com.zone_id}"
  api_swaggers = ["${data.template_file.api_swagger.rendered}"]
  api_stages = ["${var.api_stages}"]
  domain = "guiadev.scilonax.com"
  cdn_origin_id = "guiadev_scilonax_com"
  acm_certificate_arn = "${aws_acm_certificate.cert.arn}"
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
  lambda_apis     = ["post-ride"]
  api_lambdas     = ["0"]
}

data "template_file" "api_swagger" {
  template = "${file("swagger.yaml")}"
 
  vars {
    user_pool_arn  = "${module.serverless.cognito_user_pool_arn}"
    post_ride_lambda_arn = "${element(module.serverless.lambda_invoke_arns, 0)}"
  }
}

data "template_file" "config_js" {
  template = "${file("config.js")}"
 
  vars {
    cognito_user_pool_id = "${module.serverless.cognito_user_pool_id}"
    cognito_user_pool_client_id = "${module.serverless.cognito_user_pool_client_id}"
  }
}

resource "local_file" "config_js" {
    content     = "${data.template_file.config_js.rendered}"
    filename = "${path.module}/website/js/config.js"
}
