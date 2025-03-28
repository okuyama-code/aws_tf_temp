variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "environment" {
  description = "Environment name (stg, prod)"
  type        = string
  default     = "stg"
}

variable "project_name" {
  type    = string
  default = "my-app"
}

variable "ssh_allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
