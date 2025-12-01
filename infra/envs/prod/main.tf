module "eks_3api" {
  source = "../../modules/eks-3api"

  project_name = "group3"
  environment  = "prod"
  region       = "ap-southeast-1"

  cluster_version = "1.34"

  node_min     = 1
  node_desired = 1
  node_max     = 2

  azs = ["ap-southeast-1a", "ap-southeast-1b"]
  public_subnets  = ["10.0.0.0/20", "10.0.16.0/20"]
  private_subnets = ["10.0.32.0/20", "10.0.48.0/20"]

  zone_id = "Z07852252OWMU8O090PPL"
  domain  = "api.prod.theareak.click"

  acm_arn = "arn:aws:acm:us-east-1:570430250751:certificate/CHANGE_ME"

  service_a_image = "570430250751.dkr.ecr.ap-southeast-1.amazonaws.com/service-a:latest"
  service_b_image = "570430250751.dkr.ecr.ap-southeast-1.amazonaws.com/service-b:latest"
  service_c_image = "570430250751.dkr.ecr.ap-southeast-1.amazonaws.com/service-c:latest"
}
