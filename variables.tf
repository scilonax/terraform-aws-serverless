variable "domain" {
  type = string
}

variable "domain_aliases" {
  type    = list(string)
  default = []
}

variable "cdn_origin_id" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "website_folder" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "dynamodb_tables_arn" {
  type    = list
  default = []
}

variable "lambda_role_name" {
  type = string
}