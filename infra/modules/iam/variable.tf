variable "project_name" {}
variable "environment" {}

variable "cluster_oidc_issuer" {
  description = "OIDC issuer URL from EKS"
  type        = string
}