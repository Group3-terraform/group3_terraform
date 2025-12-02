
variable "hosted_zone_id" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
  description = "ACM certificate ARN for the ALB ingress HTTPS"
}
