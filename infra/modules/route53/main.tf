locals {
  create_record = (
    var.alb_dns_name != "" &&
    var.alb_zone_id  != ""
  )
}

resource "aws_route53_record" "alb" {
  for_each = local.create_record ? toset([var.record_name]) : toset([])

  zone_id = var.hosted_zone_id
  name    = each.key
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }
}
