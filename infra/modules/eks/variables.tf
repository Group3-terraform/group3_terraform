variable "project_name" {}
variable "environment" {}

variable "cluster_version" {
  default = "1.34"
}

variable "iam_role_arn" {}
variable "node_iam_role_arn" {}

variable "vpc_id" {}
variable "private_subnets" {
  type = list(string)
}

variable "node_min" {}
variable "node_desired" {}
variable "node_max" {}
 