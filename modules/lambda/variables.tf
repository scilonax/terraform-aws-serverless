variable "source_dir" {
  type = string
}

variable "function_name" {
  type = string
}

variable "bucket" {
  type = string
}

variable "function_version" {
  type = string
}

variable "handler" {
  type = string
}

variable "layers_arn" {
  type    = list
  default = []
}

variable "runtime" {
  type = string
}

variable "api_execution_arn" {
  type    = string
  default = "none"
}

variable "retention_in_days" {
  type = number
}
