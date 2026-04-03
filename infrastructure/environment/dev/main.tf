module "vpc" {
  source = "../../modules/vpc"

  name = var.project
  cidr = var.vpc_cidr

  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = var.project

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets
}

module "alb" {
  source = "../../modules/alb"

  cluster_name       = module.eks.cluster_name
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_url  = module.eks.cluster_oidc_issuer_url
  region             = var.region
  vpc_id             = module.vpc.vpc_id
}

module "external_dns" {
  source = "../../modules/external-dns"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url  
  domain            = "arkadevops.in"
  region            = var.region
}

module "acm" {
  source = "../../modules/acm"

  domain  = "arkadevops.in"
  zone_id = var.zone_id
}