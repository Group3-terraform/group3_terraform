data "aws_region" "current" {}

# Map of ALB hosted zone IDs by region
locals {
  alb_zone_ids = {
    "us-east-1"      = "Z35SXDOTRQ7X7K"
    "us-west-2"      = "Z1H1FL5HABSF5"
    "ap-southeast-1" = "Z1LMS91P8CMLE5"
    "ap-southeast-2" = "Z1GM3OXH4ZPM65"
  }
}

###########################
# Outputs
###########################

# Ingress hostname (your domain)
output "ingress_hostname" {
  value = var.ingress_hostname
}

# Dynamic ALB zone ID (region-aware)
output "alb_zone_id" {
  value = local.alb_zone_ids[data.aws_region.current.name]
}

# ALB name (used to lookup the real ALB in root module)
output "alb_name" {
  value = "${var.project_name}-${var.environment}-alb"
}
