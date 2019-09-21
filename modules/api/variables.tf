variable "name" {
    type = string
}

variable "swagger" {
    type = string
}

variable "domain" {
    type = string
}

variable "acm_certificate_arn" {
    type = string
}

variable "zone_id" {
    type = string
}

variable "green_deploy_count" {
    type = number
}

variable "blue_deploy_count" {
    type = number
}

variable "current_stage" {
    type = string
}

variable "path_version" {
    type = string
}
