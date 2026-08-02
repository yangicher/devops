terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = local.region
}

locals {
  region       = "us-west-2"
  project      = "lesson-7"
  cluster_name = "lesson-7-eks"
}

# S3 + DynamoDB для стейту вже створені в lesson-5 і використовуються через backend.tf.
# Модуль лишається в проєкті і вмикається змінною, якщо бекенд треба створити з нуля.
variable "create_state_backend" {
  type        = bool
  description = "Створити S3 бакет і DynamoDB таблицю для стейту (вже існують з lesson-5)"
  default     = false
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

  # Теги, без яких EKS не знайде підмережі для LoadBalancer-сервісів
  cluster_name = local.cluster_name
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

  # t3.small — один з небагатьох типів, дозволених на Free Tier акаунті
  # (t3.medium відхиляється з InvalidParameterCombination)
  node_instance_types = ["t3.small"]
  node_desired_size   = 2
  node_min_size       = 2
  node_max_size       = 4

  # metrics-server потрібен, щоб HPA бачив завантаження CPU
  cluster_addons = ["vpc-cni", "kube-proxy", "coredns", "metrics-server"]
}
