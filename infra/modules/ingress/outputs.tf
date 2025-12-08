output "ingress_hostname" {
  value = var.ingress_hostname
}

output "alb_dns_name" {
  value = kubernetes_ingress_v1.apps_ingress.status[0].load_balancer[0].ingress[0].hostname
}

output "alb_zone_id" {
  value = data.aws_lb.apps_alb.zone_id
}
