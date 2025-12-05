############################################
# Get Current IAM Identity
############################################
data "aws_caller_identity" "current" {}

############################################
# EKS Cluster
############################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.18"

  cluster_name    = "${var.project_name}-${var.environment}-eks"
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  enable_irsa = true

  ############################################
  # Cluster API Endpoint Options
  ############################################
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  ############################################
  # IAM Roles for Cluster & Nodes
  ############################################
  iam_role_arn      = var.iam_role_arn
  node_iam_role_arn = var.node_iam_role_arn

  ############################################
  # ADD THIS: RBAC FIX – Give Terraform Access
  ############################################
  manage_aws_auth_configmap = true

  aws_auth_users = [
    {
      userarn  = data.aws_caller_identity.current.arn
      username = "terraform-admin"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_roles = [
    {
      rolearn  = var.node_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes"
      ]
    }
  ]

  ############################################
  # Node Group
  ############################################
  eks_managed_node_groups = {
    default = {
      min_size     = var.node_min
      max_size     = var.node_max
      desired_size = var.node_desired

      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"

      iam_role_arn = var.node_iam_role_arn
    }
  }
}
