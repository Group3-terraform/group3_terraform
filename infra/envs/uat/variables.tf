###############################
# Global vars
###############################

variable "project_name" {}
variable "environment"  {}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "cluster_version" {
  type    = string
  default = "1.34"
}

variable "azs" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "node_min" {
  type = number
}

variable "node_desired" {
  type = number
}

variable "node_max" {
  type = number
}

###############################
# Domain / DNS / ACM
###############################

variable "domain" {
  type = string
}

variable "subdomain" {
  type = string
  # For uat this will be "api.uat"
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID for theareak.click"
  type        = string
}

###############################
# (Optional) image & TLS vars you already had
###############################

variable "tls_secret_name" {
  type = string
}

variable "service_a_image" {
  type = string
}

variable "service_b_image" {
  type = string
}

variable "service_c_image" {
  type = string
}

variable "zone_id" {
  type = string
  description = "Deprecated: use hosted_zone_id instead"
}
variable "enable_iam" {
  type    = bool
  default = true
}
