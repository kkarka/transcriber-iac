output "certificate_arn" {
  value = module.acm.certificate_arn
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_role_arn" {
  value = module.alb.alb_role_arn
}