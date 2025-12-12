locals {
  cw_namespace = "${var.project_name}-${var.environment}"
}

module "eks_observability" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16.0"

  cluster_name           = var.cluster_name
  cluster_endpoint       = var.cluster_endpoint
  cluster_ca_certificate = var.cluster_ca
  oidc_provider_arn      = var.oidc_provider_arn

  # Enable CloudWatch Metrics + Fluent Bit
  enable_aws_cloudwatch_metrics = true
  enable_aws_for_fluentbit      = true

  aws_cloudwatch_metrics = {
    namespace = "amazon-cloudwatch"
  }

  aws_for_fluentbit = {
    namespace = local.cw_namespace
    create_cw_log_group = true
  }
}
