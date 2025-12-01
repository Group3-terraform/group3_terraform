terraform {
  required_version = ">= 1.8.0"
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

provider "aws" {
  region = var.region
}
