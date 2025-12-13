variable "project_name" {}
variable "environment" {}

variable "aws_region" {}

variable "cluster_name" {}
variable "vpc_id" {}

variable "ingress_hostname" {}

# variable "alb_role_arn" {}
variable "alb_role_arn" {
  type    = string
  default = null
}
variable "acm_certificate_arn" {}
