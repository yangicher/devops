variable "namespace" {
  type        = string
  description = "Namespace для Prometheus і Grafana"
  default     = "monitoring"
}

variable "chart_version" {
  type        = string
  description = "Версія Helm-чарта kube-prometheus-stack"
  default     = "65.5.1"
}

variable "grafana_admin_password" {
  type        = string
  description = "Пароль адміністратора Grafana"
  sensitive   = true
}

variable "grafana_service_type" {
  type        = string
  description = "Тип сервісу Grafana: ClusterIP або LoadBalancer"
  default     = "LoadBalancer"
}

variable "storage_class" {
  type        = string
  description = "StorageClass для тому Prometheus"
  default     = "gp3"
}

variable "prometheus_storage_size" {
  type        = string
  description = "Розмір тому для метрик Prometheus"
  default     = "10Gi"
}

variable "prometheus_retention" {
  type        = string
  description = "Скільки зберігати метрики, наприклад 7d"
  default     = "7d"
}

variable "grafana_storage_size" {
  type        = string
  description = "Розмір тому Grafana"
  default     = "2Gi"
}

variable "app_namespace" {
  type        = string
  description = "Namespace застосунку, метрики якого збираються"
  default     = "default"
}

variable "app_label" {
  type        = string
  description = "Значення app.kubernetes.io/name для ServiceMonitor застосунку"
  default     = "django-app"
}

variable "enable_app_service_monitor" {
  type        = bool
  description = "Створити ServiceMonitor для застосунку"
  default     = false
}

variable "resources" {
  type = object({
    prometheus = object({
      requests = object({ cpu = string, memory = string })
      limits   = object({ cpu = string, memory = string })
    })
    grafana = object({
      requests = object({ cpu = string, memory = string })
      limits   = object({ cpu = string, memory = string })
    })
  })
  description = "Ресурси для Prometheus і Grafana"
  default = {
    prometheus = {
      requests = { cpu = "200m", memory = "512Mi" }
      limits   = { cpu = "1000m", memory = "1536Mi" }
    }
    grafana = {
      requests = { cpu = "50m", memory = "128Mi" }
      limits   = { cpu = "300m", memory = "384Mi" }
    }
  }
}
