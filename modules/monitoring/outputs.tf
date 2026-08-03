output "namespace" {
  value       = kubernetes_namespace.monitoring.metadata[0].name
  description = "Namespace моніторингу"
}

output "chart_version" {
  value       = helm_release.kube_prometheus_stack.version
  description = "Версія встановленого kube-prometheus-stack"
}

output "grafana_url" {
  value       = try("http://${data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].hostname}", "LoadBalancer ще піднімається")
  description = "Зовнішній URL Grafana"
}

output "grafana_admin_user" {
  value       = "admin"
  description = "Логін адміністратора Grafana"
}

output "grafana_admin_password" {
  value       = var.grafana_admin_password
  sensitive   = true
  description = "Пароль адміністратора Grafana"
}

output "prometheus_service" {
  value       = "kube-prometheus-stack-prometheus.${kubernetes_namespace.monitoring.metadata[0].name}.svc:9090"
  description = "Внутрішня адреса Prometheus"
}

output "port_forward_grafana" {
  value       = "kubectl port-forward svc/grafana 3000:80 -n ${kubernetes_namespace.monitoring.metadata[0].name}"
  description = "Команда для локального доступу до Grafana"
}

output "port_forward_prometheus" {
  value       = "kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n ${kubernetes_namespace.monitoring.metadata[0].name}"
  description = "Команда для локального доступу до Prometheus"
}
