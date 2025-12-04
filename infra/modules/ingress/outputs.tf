output "alb_service_account_name" {
  value = kubernetes_service_account_v1.alb_sa.metadata[0].name
}

output "alb_iam_role_arn" {
  value = aws_iam_role.alb_controller.arn
}

output "ingress_hostname" {
  value = var.ingress_hostname
}

output "alb_controller_policy_arn" {
  value = aws_iam_policy.alb_controller_policy.arn
}
