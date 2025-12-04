module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = "${var.project_name}-${var.environment}-eks"
  cluster_version = var.cluster_version

  enable_irsa = true

  iam_role_arn = var.iam_role_arn
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnets

  ## FIX: Terraform must reach Kubernetes API
  cluster_endpoint_public_access        = true
  cluster_endpoint_private_access       = true
  cluster_endpoint_public_access_cidrs  = ["0.0.0.0/0"]

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
