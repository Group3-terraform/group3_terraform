###############################
# Load global project variables
###############################

# variables are defined in variables.tf and filled via terraform.tfvars


##########################
# VPC module
##########################

module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
  environment  = var.environment

  vpc_cidr        = "10.0.0.0/16"
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

##########################
# IAM module (cluster & node roles)
##########################

module "iam" {
  source       = "../../modules/iam"
  project_name = var.project_name
  environment  = var.environment
}

##########################
# EKS module
##########################

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

##########################
# ACM Module (Option A)
##########################
# Creates ACM certificate for:
#   full_domain = "${var.subdomain}.${var.domain}"
# Example (dev): "api.dev.theareak.click"

module "acm" {
  source = "../../modules/acm"

  full_domain    = "${var.subdomain}.${var.domain}"
  hosted_zone_id = var.hosted_zone_id
}

##########################
# Ingress + ALB Controller + Route53
##########################

module "ingress" {
  source = "../../modules/ingress"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_id       = module.vpc.vpc_id
  cluster_name = module.eks.cluster_name

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  # For dev: "api.dev.theareak.click"
  ingress_hostname = "${var.subdomain}.${var.domain}"

  route53_zone_id      = var.hosted_zone_id
  acm_certificate_arn  = module.acm.acm_certificate_arn
}

##########################
# (Optional) outputs
##########################

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "ingress_hostname" {
  value = module.ingress.ingress_hostname
}
