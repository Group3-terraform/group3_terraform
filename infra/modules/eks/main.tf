data "aws_caller_identity" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.18"

  cluster_name    = "${var.project_name}-${var.environment}-eks"
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  enable_irsa = true

  # Cluster endpoint settings
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # IAM ROLE FIX: remove invalid fields
  # iam_role_arn      = var.iam_role_arn        ❌ REMOVE
  # node_iam_role_arn = var.node_iam_role_arn   ❌ REMOVE

  # RBAC fix
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

  eks_managed_node_groups = {
    default = {
      min_size     = var.node_min
      max_size     = var.node_max
      desired_size = var.node_desired

      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"

      iam_role_arn = var.node_iam_role_arn   # ✔ VALID here
    }
  }
}
