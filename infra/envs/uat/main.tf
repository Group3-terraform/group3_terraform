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
module "eks" {
  source = "../../modules/eks"

  project_name    = var.project_name
  environment     = var.environment
  cluster_version = var.cluster_version

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  node_iam_role_arn = module.iam.node_role_arn

  node_min     = 1
  node_max     = 4
  node_desired = 3
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
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


module "route53" {
  source = "../../modules/route53"

  hosted_zone_id = var.hosted_zone_id
  domain_name    = "${var.subdomain}.${var.domain}"  

  alb_dns_name = "group3-uat-alb-555815385.ap-southeast-1.elb.amazonaws.com"
  alb_zone_id  = "Z1LMS91P8CMLE5"
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
