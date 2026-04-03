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

module "argocd" {
  source = "../../modules/argocd"

  cluster_name = module.eks.cluster_name
  db_endpoint   = module.rds.db_endpoint
  db_user       = var.db_user
  db_pass       = var.db_pass
  bucket_name   = module.s3.bucket_name
  irsa_role_arn = module.iam.irsa_role_arn
  certificate_arn = module.acm.certificate_arn
  openai_api_key = var.openai_api_key
}

module "s3" {
  source = "../../modules/s3"

  project_name = var.project
  environment  = var.environment
}

module "rds" {
  source = "../../modules/rds"

  project_name     = var.project
  private_subnets  = module.vpc.private_subnets
  db_user          = var.db_user
  db_pass          = var.db_pass
  db_sg            = aws_security_group.rds.id
}

module "iam" {
  source = "../../modules/iam"

  project_name      = var.project
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
  bucket_arn        = module.s3.bucket_arn
}

resource "aws_security_group" "rds" {
  name   = "${var.project}-rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "18.3.2"

  namespace = "transcriber"

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "auth.enabled"
    value = "false"
  }

  set {
    name  = "master.persistence.enabled"
    value = "false"
  }

  set {
    name  = "replica.persistence.enabled"
    value = "false"
  }

  set {
    name  = "replica.replicaCount"
    value = "0"
  }

  set {
    name  = "image.repository"
    value = "redis"
  }

  set {
    name  = "image.tag"
    value = "7"
  }
}