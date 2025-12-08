resource "aws_route53_record" "alb" {

  zone_id = var.hosted_zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name != "" ? var.alb_dns_name : "dualstack.placeholder.elb.amazonaws.com"
    zone_id                = var.alb_zone_id  != "" ? var.alb_zone_id  : "Z1LMS91P8CMLE5"
    evaluate_target_health = false
  }

  lifecycle {
    ignore_changes = [
      alias,
    ]
  }
}
