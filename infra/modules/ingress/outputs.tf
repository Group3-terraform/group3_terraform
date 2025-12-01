output "ingress_name" {
  value = kubernetes_ingress_v1.apps_ingress.metadata[0].name
}
