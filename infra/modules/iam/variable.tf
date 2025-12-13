variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_oidc_issuer" {
  type = string
  locals {
  oidc_hostpath = replace(var.cluster_oidc_issuer, "https://", "")
}

}