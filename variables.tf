variable "domain" {}
variable "cdn_origin_id" {}
variable "acm_certificate_arn" {}
variable "route53_zone_id" {}
variable "api_swagger" {}

variable "website_folder" {}
variable "aws_profile" {}

variable "dynamodb_tables" {
  type = "list"
  default = []
}

variable "dynamodb_table_hash_keys" {
  type = "list"
  default = []
}

variable "dynamodb_table_range_keys" {
  type = "list"
  default = []
}

variable "dynamodb_table_attributes" {
  type = "list"
  default = []
}

variable "lambdas" {
  type = "list"
  default = []
}

variable "lambda_handlers" {
  type = "list"
  default = []
}

variable "lambda_runtimes" {
  type = "list"
  default = []
}

variable "lambda_versions" {
  type = "list"
  default = []
}

variable "lambda_files" {
  type = "list"
  default = []
}
