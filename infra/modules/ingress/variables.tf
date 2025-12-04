variable "project_name" { type = string }
variable "environment"  { type = string }

variable "aws_region"   { type = string }
variable "vpc_id"       { type = string }

variable "cluster_name" { type = string }

variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }

variable "ingress_hostname" { type = string }
variable "route53_zone_id"  { type = string }
variable "acm_certificate_arn" { type = string }
