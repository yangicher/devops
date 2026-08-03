output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID створеної VPC"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Ім'я EKS кластера"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "API endpoint кластера"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "URL ECR репозиторію для Docker-образу Django"
}

output "kubeconfig_command" {
  value       = "aws eks update-kubeconfig --region ${local.region} --name ${module.eks.cluster_name}"
  description = "Команда для налаштування доступу через kubectl"
}

output "jenkins_url" {
  value       = module.jenkins.url
  description = "Зовнішній URL Jenkins"
}

output "jenkins_admin_user" {
  value       = module.jenkins.admin_user
  description = "Логін адміністратора Jenkins"
}

output "jenkins_admin_password" {
  value       = module.jenkins.admin_password
  sensitive   = true
  description = "Пароль адміністратора Jenkins"
}

output "jenkins_irsa_role_arn" {
  value       = module.jenkins.service_account_role_arn
  description = "IAM роль агентів Jenkins для push у ECR"
}

output "argocd_url" {
  value       = module.argo_cd.url
  description = "Зовнішній URL Argo CD UI"
}

output "argocd_admin_password" {
  value       = module.argo_cd.admin_password
  sensitive   = true
  description = "Початковий пароль admin Argo CD"
}

output "argocd_application" {
  value       = module.argo_cd.application_name
  description = "Ім'я Argo CD Application"
}

output "db_endpoint" {
  value       = module.rds.endpoint
  description = "Хост БД для підключення застосунку"
}

output "db_reader_endpoint" {
  value       = module.rds.reader_endpoint
  description = "Reader endpoint (тільки для Aurora)"
}

output "db_port" {
  value       = module.rds.port
  description = "Порт БД"
}

output "db_identifier" {
  value       = module.rds.identifier
  description = "Ідентифікатор кластера або інстансу БД"
}

output "db_security_group_id" {
  value       = module.rds.security_group_id
  description = "Security group БД"
}

output "db_is_aurora" {
  value       = module.rds.is_aurora
  description = "Чи створено Aurora-кластер"
}

output "grafana_url" {
  value       = module.monitoring.grafana_url
  description = "Зовнішній URL Grafana"
}

output "grafana_admin_password" {
  value       = module.monitoring.grafana_admin_password
  sensitive   = true
  description = "Пароль адміністратора Grafana"
}

output "monitoring_namespace" {
  value       = module.monitoring.namespace
  description = "Namespace моніторингу"
}

output "port_forward_commands" {
  value = {
    jenkins    = "kubectl port-forward svc/jenkins 8080:8080 -n ${module.jenkins.namespace}"
    argocd     = "kubectl port-forward svc/argocd-server 8081:443 -n ${module.argo_cd.namespace}"
    grafana    = module.monitoring.port_forward_grafana
    prometheus = module.monitoring.port_forward_prometheus
  }
  description = "Команди локального доступу до сервісів"
}
