variable "full_domain" {
  description = "FQDN for ACM certificate, e.g., api.dev.theareak.click"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for parent domain"
  type        = string
}
