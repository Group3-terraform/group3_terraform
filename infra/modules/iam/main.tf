############################################
# DATA: AWS Account ID
############################################
data "aws_caller_identity" "current" {}

############################################
# DATA: EKS Cluster & OIDC Information
############################################
data "aws_eks_cluster" "eks" {
  name = "${var.project_name}-${var.environment}-eks"
}

data "aws_eks_cluster_auth" "eks" {
  name = data.aws_eks_cluster.eks.name
}

locals {
  oidc_url      = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
  oidc_hostpath = replace(local.oidc_url, "https://", "")
}

############################################
# IAM OIDC Provider (IRSA)
############################################
resource "aws_iam_openid_connect_provider" "eks" {
  url             = local.oidc_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd80e35"]
}

############################################
# EKS Cluster IAM Role
############################################
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

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
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_hostpath}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller",
          "${local.oidc_hostpath}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

############################################
# ALB Controller IAM Policy
############################################
resource "aws_iam_policy" "alb_controller_policy" {
  name   = "${var.project_name}-${var.environment}-alb-controller-policy"
  policy = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

############################################
# Outputs
############################################
output "cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller_role.arn
}
