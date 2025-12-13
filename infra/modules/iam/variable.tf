variable "cluster_oidc_issuer" {
  type        = string
  description = "OIDC issuer URL from EKS cluster"
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}
