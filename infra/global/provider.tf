variable "region" {
  type        = string
  description = "AWS region to deploy into"
}

provider "aws" {
  region = var.region
}
