output "alb_dns_name" {
  value = try(
    kubernetes_ingress_v1.apps_ingress.status[0].load_balancer[0].ingress[0].hostname,
    ""
  )
}

data "aws_elb_service_account" "this" {}

data "aws_region" "current" {}

locals {
  alb_zone_ids = {
    "ap-southeast-1" = "Z1LMS91P8CMLE5"
    "ap-southeast-2" = "Z1GM3OXH4ZPM65"
    "us-east-1"      = "Z35SXDOTRQ7X7K"
    "us-west-2"      = "Z1H1FL5HABSF5"
  }
}

output "alb_zone_id" {
  value = lookup(local.alb_zone_ids, data.aws_region.current.name, "")
}


# output "ingress_hostname" {
#   value = var.ingress_hostname
# }

# output "alb_dns_name" {
#   value = try(
#     kubernetes_ingress_v1.apps_ingress.status[0].load_balancer[0].ingress[0].hostname,
#     ""
#   )
# }

# output "alb_zone_id" {
#   value = try(
#     data.aws_lb.apps_alb.zone_id,
#     ""
#   )
# }
