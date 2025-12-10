resource "aws_route53_record" "alb" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name         # e.g. api.dev.theareak.click
  type    = "A"

  alias {
    name                   = var.alb_dns_name   # e.g. group3-dev-alb-5558...elb.amazonaws.com
    zone_id                = var.alb_zone_id    # e.g. Z1LMS91P8CMLE5
    evaluate_target_health = false
  }
}
