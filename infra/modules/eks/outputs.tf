output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca" {
  value = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc_provider[0].arn
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.oidc_provider[0].url
}
