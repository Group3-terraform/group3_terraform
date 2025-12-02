###############################
# Load global project variables
###############################

variable "project_name" {}
variable "environment"  {}

variable "cluster_version" {
  type    = string
  default = "1.34"
}

variable "azs" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "node_min" {
  type = number
}

variable "node_desired" {
  type = number
}

variable "node_max" {
  type = number
}

variable "domain" {
  type = string
}

variable "tls_secret_name" {
  type = string
}

variable "service_a_image" {
  type = string
}

variable "service_b_image" {
  type = string
}

variable "service_c_image" {
  type = string
}

##########################
# IAM module
##########################

module "iam" {
  source       = "../../modules/iam"
  project_name = var.project_name
  environment  = var.environment
}

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

###################################################
# Load EKS connection details after cluster exists
###################################################

# data "aws_eks_cluster" "this" {
#   name = module.eks.cluster_name
# }

# data "aws_eks_cluster_auth" "this" {
#   name = module.eks.cluster_name
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.this.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.this.token
# }

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"

    args = [
      "eks",
      "--region", "ap-southeast-1",
      "get-token",
      "--cluster-name", module.eks.cluster_name
    ]
  }
}



##########################
# Ingress + Services
##########################

module "ingress" {
  source = "../../modules/ingress"

  providers = {
    kubernetes = kubernetes
  }

  # Make sure Kubernetes objects are only created AFTER EKS is ready
  depends_on = [module.eks]

  domain          = var.domain
  tls_secret_name = var.tls_secret_name

  service_a_image = var.service_a_image
  service_b_image = var.service_b_image
  service_c_image = var.service_c_image
}
#Route 53 Record for Ingress
data "aws_lb" "ingress" {
  name = split("-", split(".", module.ingress.ingress_hostname)[0])[0]
}

resource "aws_route53_record" "apps_ingress_dns" {
  zone_id = var.hosted_zone_id
  name    = "api.dev.${var.domain}"
  type    = "A"

  alias {
    name                   = module.ingress.ingress_hostname
    zone_id                = data.aws_lb.ingress.zone_id
    evaluate_target_health = false
  }

  depends_on = [
    module.ingress
  ]
}
