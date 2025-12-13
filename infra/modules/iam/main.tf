############################################
# DATA: AWS Account ID
############################################
data "aws_caller_identity" "current" {}

############################################
# DATA: EKS Cluster (for OIDC)
############################################
# data "aws_eks_cluster" "eks" {
#   name = "${var.project_name}-${var.environment}-eks"
# }

############################################
# LOCALS: OIDC Hostpath & ARN
############################################
# locals {
#   oidc_hostpath = var.cluster_oidc_issuer != null
#     ? replace(var.cluster_oidc_issuer, "https://", "")
#     : ""
# }




############################################
# EKS Cluster IAM Role
############################################
# resource "aws_iam_role" "eks_cluster_role" {
#   name = "${var.project_name}-${var.environment}-eks-cluster-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "eks.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

############################################
# EKS Node IAM Role
############################################
resource "aws_iam_role" "eks_node_role" {
  name = "${var.project_name}-${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

############################################
# ALB Controller IAM Role (IRSA)
############################################
resource "aws_iam_role" "alb_controller_role" {
  name = "${var.project_name}-${var.environment}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        # Use existing OIDC provider ARN (do NOT create new one)
        Federated = local.oidc_provider_arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          # Restrict to this ServiceAccount
          "${local.oidc_hostpath}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller",
          "${local.oidc_hostpath}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "alb_controller_policy" {
  name   = "${var.project_name}-${var.environment}-alb-controller-policy"
  policy = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}
