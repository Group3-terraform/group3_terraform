#########################################
# VPC Module (FIXED with ALB/EKS tags)
#########################################

module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
  environment  = var.environment

  vpc_cidr        = "10.0.0.0/16"
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  # REQUIRED FOR EKS & ALB CONTROLLER
  enable_dns_support   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}-eks" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}-eks" = "shared"
  }
}


#########################################
# IAM Module (Cluster + Node + ALB IRSA)
#########################################

module "iam" {
  source       = "../../modules/iam"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}


#########################################
# EKS Module
#########################################

module "eks" {
  source = "../../modules/eks"

  project_name    = var.project_name
  environment     = var.environment
  cluster_version = var.cluster_version

  iam_role_arn      = module.iam.cluster_role_arn
  node_iam_role_arn = module.iam.node_role_arn

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  node_min     = var.node_min
  node_desired = var.node_desired
  node_max     = var.node_max
}

#########################################
# ACM Module (Issue Certificate)
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

  vpc_id       = module.vpc.vpc_id
  cluster_name = module.eks.cluster_name

  alb_role_arn        = module.iam.alb_controller_role_arn
  acm_certificate_arn = module.acm.acm_certificate_arn

  ingress_hostname = "${var.subdomain}.${var.domain}"
}

# data "aws_lb" "apps_alb" {
#   depends_on = [ module.ingress ]
#   name       = module.ingress.alb_name
# }

module "route53" {
  source = "../../modules/route53"

  hosted_zone_id = var.hosted_zone_id
  domain_name    = "${var.subdomain}.${var.domain}"   # api.dev.theareak.click

  # For dev (what you already know from AWS console):
  alb_dns_name = "group3-dev-alb-555815385.ap-southeast-1.elb.amazonaws.com"
  alb_zone_id  = "Z1LMS91P8CMLE5"
  # alb_dns_name = data.aws_lb.apps_alb.dns_name
  # alb_zone_id  = data.aws_lb.apps_alb.zone_id
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
