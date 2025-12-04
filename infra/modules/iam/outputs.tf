output "cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "node_role_name" {
  value = aws_iam_role.eks_node_role.name
}

output "alb_role_arn"     { value = aws_iam_role.alb_controller_role.arn }