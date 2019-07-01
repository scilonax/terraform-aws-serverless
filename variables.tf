variable "domain" {
}

variable "cdn_origin_id" {
}

variable "acm_certificate_arn" {
}

variable "route53_zone_id" {
}

variable "api_swaggers" {
  type    = list(string)
  default = []
}

variable "api_versions" {
  type    = list(string)
  default = []
}

variable "api_stages" {
  type    = list(string)
  default = []
}

variable "api_green_deploy_numbers" {
  type    = list(string)
  default = []
}

variable "api_blue_deploy_numbers" {
  type    = list(string)
  default = []
}

variable "website_folder" {
}

variable "aws_profile" {
}

variable "dynamodb_tables" {
  type    = list(string)
  default = []
}

variable "dynamodb_table_hash_keys" {
  type    = list(string)
  default = []
}

variable "dynamodb_table_range_keys" {
  type    = list(string)
  default = []
}

variable "dynamodb_table_attributes" {
  type    = list(object({
    name = string
    type = string
  }))
  default = []
}

variable "lambdas" {
  type    = list(string)
  default = []
}

variable "lambda_handlers" {
  type    = list(string)
  default = []
}

variable "lambda_runtimes" {
  type    = list(string)
  default = []
}

variable "lambda_versions" {
  type    = list(string)
  default = []
}

variable "lambda_files" {
  type    = list(string)
  default = []
}

variable "lambda_apis" {
  type    = list(string)
  default = []
}

variable "api_lambdas" {
  type    = list(string)
  default = []
}

