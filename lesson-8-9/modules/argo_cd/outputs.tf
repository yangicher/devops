output "namespace" {
  value       = kubernetes_namespace.argocd.metadata[0].name
  description = "Namespace, у якому працює Argo CD"
}

output "chart_version" {
  value       = helm_release.argocd.version
  description = "Версія встановленого чарта Argo CD"
}

output "hostname" {
  value       = try(data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname, "LoadBalancer ще піднімається")
  description = "Зовнішній hostname argocd-server"
}

output "url" {
  value       = try("http://${data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname}", "LoadBalancer ще піднімається")
  description = "Зовнішній URL Argo CD UI"
}

output "admin_password" {
  value       = try(data.kubernetes_secret.argocd_admin.data["password"], "")
  sensitive   = true
  description = "Початковий пароль admin (terraform output -raw argocd_admin_password)"
}

output "application_name" {
  value       = var.application_name
  description = "Ім'я Argo CD Application"
}
