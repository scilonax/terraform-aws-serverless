provider "aws" {
  region = "us-east-1"
  profile = "scilonax"
}

data "aws_route53_zone" "scilonax_com" {
  name = "scilonax.com"
}

data "aws_acm_certificate" "scilonax_com" {
  domain = "scilonax.com"
}

module "serverless" {
  source = "../../"
  aws_profile = "scilonax"
  website_folder = "website"
  route53_zone_id = "${data.aws_route53_zone.scilonax_com.zone_id}"
  api_swagger = "${data.template_file.api_swagger.rendered}"
  domain = "guiadev.scilonax.com"
  cdn_origin_id = "guiadev_scilonax_com"
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

data "template_file" "config_js" {
  template = "${file("config.js")}"
 
  vars {
    cognito_user_pool_id = "${module.serverless.cognito_user_pool_id}"
    cognito_user_pool_client_id = "${module.serverless.cognito_user_pool_client_id}"
    aws_api_gateway_prod_invoke_url = "${module.serverless.aws_api_gateway_prod_invoke_url}"
  }
}

resource "local_file" "config_js" {
    content     = "${data.template_file.config_js.rendered}"
    filename = "${path.module}/website/js/config.js"
}
