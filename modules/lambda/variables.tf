variable "source_file" {
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
  type = list
}

variable "runtime" {
  type = string
}

variable "api_execution_arn" {
  type = string
}

variable "retention_in_days" {
  type = number
}
