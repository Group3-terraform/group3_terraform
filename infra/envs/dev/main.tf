#########################################
# VPC Module
#########################################

module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
  environment  = var.environment

  vpc_cidr        = "10.0.0.0/16"
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

#########################################
# IAM Module (Cluster + Node + ALB IRSA)
#########################################

module "iam" {
  source       = "../../modules/iam"
  project_name = var.project_name
  environment  = var.environment
}

#########################################
# EKS Module
#########################################

module "eks" {
  source = "../../modules/eks"

  project_name    = var.project_name
  environment     = var.environment
  cluster_version = var.cluster_version

  # IAM Roles from IAM module
  iam_role_arn      = module.iam.cluster_role_arn
  node_iam_role_arn = module.iam.node_role_arn

  # Networking
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  # Node scaling
  node_min     = var.node_min
  node_desired = var.node_desired
  node_max     = var.node_max
}

#########################################
# Kubernetes Provider (Activated After EKS Ready)
#########################################

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks",
      "get-token",
      "--region", var.aws_region,
      "--cluster-name", module.eks.cluster_name
    ]
  }

  depends_on = [module.eks]
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = [
        "eks",
        "get-token",
        "--region", var.aws_region,
        "--cluster-name", module.eks.cluster_name
      ]
    }
  }

  depends_on = [module.eks]
}

#########################################
# ACM Module (Certificate for ALB)
#########################################

module "acm" {
  source = "../../modules/acm"

  full_domain    = "${var.subdomain}.${var.domain}"
  hosted_zone_id = var.hosted_zone_id
}

#########################################
# Ingress Module (ALB Controller + Ingress)
#########################################

module "ingress" {
  source = "../../modules/ingress"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # Required for ALB Controller Helm chart
  vpc_id       = module.vpc.vpc_id
  cluster_name = module.eks.cluster_name

  # IRSA role from IAM module
  alb_role_arn = module.iam.alb_controller_role_arn

  # TLS
  acm_certificate_arn = module.acm.acm_certificate_arn

  # DNS hostname for ingress
  ingress_hostname = "${var.subdomain}.${var.domain}"

  depends_on = [
    module.eks,
    module.iam,
    module.acm
  ]
}

#########################################
# Outputs
#########################################

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "ingress_hostname" {
  value = "${var.subdomain}.${var.domain}"
}
