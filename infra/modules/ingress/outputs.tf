output "ingress_name" {
  value = kubernetes_ingress_v1.apps_ingress.metadata[0].name
}
output "ingress_hostname" {
  value = kubernetes_ingress_v1.apps_ingress.status[0].load_balancer[0].ingress[0].hostname
}
