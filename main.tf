terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
    }
  }
}

locals {
  region       = "us-west-2"
  project      = "final"
  cluster_name = "final-eks"
  repo_url     = "https://github.com/yangicher/devops.git"
  chart_path   = "charts/django-app"
}

variable "create_state_backend" {
  type        = bool
  description = "Створити S3 бакет і DynamoDB таблицю для стейту (вже існують з lesson-5)"
  default     = false
}

variable "jenkins_admin_password" {
  type        = string
  description = "Пароль адміністратора Jenkins"
  sensitive   = true
}

variable "github_username" {
  type        = string
  description = "Користувач GitHub, від імені якого pipeline пушить у main"
}

variable "github_token" {
  type        = string
  description = "GitHub Personal Access Token з правом запису (TF_VAR_github_token)"
  sensitive   = true
}

variable "git_branch" {
  type        = string
  description = "Гілка, з якої Jenkins бере Jenkinsfile і в яку пушить оновлений тег"
  default     = "main"
}

variable "use_aurora" {
  type        = bool
  description = "true — Aurora-кластер, false — звичайна RDS instance"
  default     = false
}

variable "db_password" {
  type        = string
  description = "Пароль master-користувача БД (TF_VAR_db_password)"
  sensitive   = true
}

variable "grafana_admin_password" {
  type        = string
  description = "Пароль адміністратора Grafana (TF_VAR_grafana_admin_password)"
  sensitive   = true
}

module "s3_backend" {
  source = "./modules/s3-backend"
  count  = var.create_state_backend ? 1 : 0

  bucket_name = "yangicher-devops-tf-state-2026"
  table_name  = "terraform-locks"
}

module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "${local.project}-vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  cluster_name       = local.cluster_name
}

module "ecr" {
  source = "./modules/ecr"

  ecr_name     = "${local.project}-django"
  scan_on_push = true
  force_delete = true
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = local.cluster_name
  cluster_version    = "1.33"
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  node_instance_types = ["c7i-flex.large"]
  node_desired_size   = 2
  node_min_size       = 2
  node_max_size       = 4

  cluster_addons = ["vpc-cni", "kube-proxy", "coredns", "metrics-server"]
}

module "rds" {
  source = "./modules/rds"

  name       = "${local.project}-db"
  use_aurora = var.use_aurora

  engine         = var.use_aurora ? "aurora-postgresql" : "postgres"
  engine_version = var.use_aurora ? "16.14" : "16.14"
  instance_class = var.use_aurora ? "db.t3.medium" : "db.t4g.micro"
  multi_az       = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_cidr_blocks        = [module.vpc.vpc_cidr_block]
  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  db_name  = "djangodb"
  username = "djangoadmin"
  password = var.db_password

  parameters = {
    max_connections = { value = "200", apply_method = "pending-reboot" }
  }

  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = 1
}

resource "kubernetes_secret" "django_db" {
  metadata {
    name      = "django-db"
    namespace = "default"
  }

  data = {
    DJANGO_DB_ENGINE  = "django.db.backends.postgresql"
    POSTGRES_HOST     = module.rds.endpoint
    POSTGRES_PORT     = tostring(module.rds.port)
    POSTGRES_DB       = module.rds.database_name
    POSTGRES_USER     = module.rds.username
    POSTGRES_PASSWORD = var.db_password
  }

  type = "Opaque"

  depends_on = [module.eks, module.rds]
}

module "jenkins" {
  source = "./modules/jenkins"

  cluster_name       = module.eks.cluster_name
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_url  = module.eks.oidc_provider_url
  storage_class      = module.eks.storage_class_name
  ecr_repository_arn = module.ecr.repository_arn
  ecr_repository_url = module.ecr.repository_url
  aws_region         = local.region

  admin_password  = var.jenkins_admin_password
  github_repo_url = local.repo_url
  github_username = var.github_username
  github_token    = var.github_token
  git_branch      = var.git_branch

  values_file_path = "${local.chart_path}/values.yaml"
}

module "monitoring" {
  source = "./modules/monitoring"

  namespace              = "monitoring"
  grafana_admin_password = var.grafana_admin_password
  grafana_service_type   = "LoadBalancer"
  storage_class          = module.eks.storage_class_name

  prometheus_retention    = "7d"
  prometheus_storage_size = "10Gi"
  grafana_storage_size    = "2Gi"

  app_namespace = "default"
  app_label     = "django-app"

  depends_on = [module.eks]
}

module "argo_cd" {
  source = "./modules/argo_cd"

  repo_url        = local.repo_url
  target_revision = var.git_branch
  chart_path      = local.chart_path

  application_name      = "django-app"
  destination_namespace = "default"

  automated_sync = true
  prune          = true
  self_heal      = true

  depends_on = [module.eks]
}
