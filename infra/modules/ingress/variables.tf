variable "project_name" {}
variable "environment" {}

variable "cluster_name" {}
variable "region" {}


variable "acm_certificate_arn" {}
variable "oidc_provider_url" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}
