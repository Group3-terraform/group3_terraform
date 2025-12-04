
variable "hosted_zone_id" {
  type = string
}
variable "zone_id" {
  type = string
}


variable "subdomain" {
  type = string
}


variable "acm_certificate_arn" {
  type        = string
  description = "ACM Certificate ARN used for the ALB Ingress Controller"
}

variable "route53_zone_id" {}
variable "ingress_hostname" {}
# variable "region" {}
