data "aws_caller_identity" "current" {}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "name" {
  type    = string
  default = "my-app-prod"
}

variable "service_name" {
  type    = string
  default = "my-app"
}

variable "environment" {
  type    = string
  default = "prod"
}
