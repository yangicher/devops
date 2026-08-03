output "namespace" {
  value       = kubernetes_namespace.jenkins.metadata[0].name
  description = "Namespace, у якому працює Jenkins"
}

output "release_name" {
  value       = helm_release.jenkins.name
  description = "Ім'я Helm release"
}

output "chart_version" {
  value       = helm_release.jenkins.version
  description = "Версія встановленого чарта"
}

output "service_account_role_arn" {
  value       = aws_iam_role.jenkins.arn
  description = "IAM роль (IRSA), під якою агенти пушать образи в ECR"
}

output "url" {
  value       = try("http://${data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress[0].hostname}:8080", "LoadBalancer ще піднімається")
  description = "Зовнішній URL Jenkins"
}

output "admin_user" {
  value       = var.admin_user
  description = "Логін адміністратора"
}

output "admin_password" {
  value       = var.admin_password
  sensitive   = true
  description = "Пароль адміністратора (terraform output -raw jenkins_admin_password)"
}
