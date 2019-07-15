variable "domain" {
}

variable "cdn_origin_id" {
}

variable "acm_certificate_arn" {
}

variable "route53_zone_id" {
}

variable "apis" {
  type    = list(object({
    swagger = string
    version = string
    stage = string
    green_deploy_count = number
    blue_deploy_count = number
  }))
  default = []
}

variable "website_folder" {
}

variable "aws_profile" {
}

variable "dynamodb_tables" {
  type    = list(object({
    name = string
    hash_key = string
    range_key = string
    attributes = list(object({
      name = string
      type = string
    }))
  }))
  default = []
}

variable "lambdas" {
  type    = list(object({
    name = string
    handler = string
    runtime = string
    version = string
    file = string
  }))
  default = []
}

variable "api_lambda_permissions" {
  type    = list(object({
    lambda = string
    api_index = number
  }))
  default = []
}
