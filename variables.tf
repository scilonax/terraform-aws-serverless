variable "domain" {
  type = string
}

variable "cdn_origin_id" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "route53_zone_id" {
  type = string
}

variable "website_folder" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "dynamodb_tables_arn" {
  type = list
}

variable "lambda_role_name" {
  type = string
}