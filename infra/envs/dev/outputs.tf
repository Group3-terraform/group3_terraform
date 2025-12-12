#########################################
# Outputs
#########################################

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "ingress_hostname" {
  value = "${var.subdomain}.${var.domain}"
}
