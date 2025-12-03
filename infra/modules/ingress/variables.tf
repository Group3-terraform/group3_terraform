variable "service_a_image" {
  type = string
}

variable "service_b_image" {
  type = string
}

variable "service_c_image" {
  type = string
}

variable "domain" {
  type = string
}

variable "tls_secret_name" {
  type        = string
  description = "Kubernetes TLS secret for NGINX ingress (cert + key)"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM Certificate ARN used for the ALB Ingress Controller"
}



variable "subdomain" {
  type = string
}

variable "alb_role_arn" {
  type = string
}
