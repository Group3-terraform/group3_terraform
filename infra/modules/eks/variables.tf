variable "project_name" {}
variable "environment" {}

variable "cluster_version" {}

variable "vpc_id" {}
variable "private_subnets" {
  type = list(string)
}

variable "node_iam_role_arn" {}

variable "node_min" {}
variable "node_max" {}
variable "node_desired" {}
