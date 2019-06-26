variable "domain" {}
variable "cdn_origin_id" {}
variable "acm_certificate_arn" {}
variable "route53_zone_id" {}
variable "api_swagger" {}

variable "dynamodb_tables" {
  type = "list"
}

variable "dynamodb_table_hash_keys" {
  type = "list"
}

variable "dynamodb_table_range_keys" {
  type = "list"
}

variable "dynamodb_table_attributes" {
  type = "list"
}

variable "lambdas" {
  type = "list"
}

variable "lambda_handlers" {
  type = "list"
}

variable "lambda_runtimes" {
  type = "list"
}

variable "lambda_versions" {
  type = "list"
}

variable "lambda_files" {
  type = "list"
}
