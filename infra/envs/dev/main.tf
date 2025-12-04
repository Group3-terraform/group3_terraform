#########################################
# Load Variables
#########################################

variable "project_name" {}
variable "environment" {}
variable "domain" {}
variable "subdomain" {}
variable "aws_region" {}

variable "cluster_version" {}
variable "azs" {}
variable "public_subnets" {}
variable "private_subnets" {}
variable "node_min" {}
variable "node_desired" {}
variable "node_max" {}
variable "hosted_zone_id" {}

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
# IAM Module (Cluster roles + ALB IRSA)
#########################################

module "iam" {
  source       = "../../modules/iam"
  project_name = var.project_name
  environment  = var.environment

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
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
# Kubernetes Provider (AFTER EKS READY)
#########################################

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--region", var.aws_region,
      "--cluster-name", module.eks.cluster_name
    ]
  }

  depends_on = [module.eks]
}

#########################################
# ACM Module (Auto Certificate)
#########################################

module "acm" {
  source = "../../modules/acm"

  full_domain    = "${var.subdomain}.${var.domain}"
  hosted_zone_id = var.hosted_zone_id
}

#########################################
# Ingress Module (ALB + Services + DNS)
#########################################

module "ingress" {
  source = "../../modules/ingress"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_id       = module.vpc.vpc_id
  cluster_name = module.eks.cluster_name

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  ingress_hostname = "${var.subdomain}.${var.domain}"
  route53_zone_id  = var.hosted_zone_id

  acm_certificate_arn = module.acm.acm_certificate_arn

  depends_on = [
    module.eks,
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
