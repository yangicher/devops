output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID створеної VPC"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Публічні підмережі (LoadBalancer)"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Приватні підмережі (worker nodes)"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "URL ECR репозиторію для Docker-образу Django"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Ім'я EKS кластера"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "API endpoint кластера"
}

output "cluster_version" {
  value       = module.eks.cluster_version
  description = "Версія Kubernetes"
}

output "node_group_name" {
  value       = module.eks.node_group_name
  description = "Ім'я групи нод"
}

output "kubeconfig_command" {
  value       = "aws eks update-kubeconfig --region ${local.region} --name ${module.eks.cluster_name}"
  description = "Команда для налаштування доступу через kubectl"
}
