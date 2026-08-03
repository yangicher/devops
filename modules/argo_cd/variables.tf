variable "namespace" {
  type        = string
  description = "Namespace для Argo CD"
  default     = "argocd"
}

variable "chart_version" {
  type        = string
  description = "Версія Helm-чарта argo-cd"
  default     = "7.7.11"
}

variable "service_type" {
  type        = string
  description = "Тип сервісу argocd-server"
  default     = "LoadBalancer"
}

variable "repo_url" {
  type        = string
  description = "Git-репозиторій, за яким стежить Argo CD"
}

variable "target_revision" {
  type        = string
  description = "Гілка репозиторію, з якої синхронізується застосунок"
  default     = "main"
}

variable "chart_path" {
  type        = string
  description = "Шлях до Helm-чарта застосунку всередині репозиторію"
}

variable "application_name" {
  type        = string
  description = "Ім'я Argo CD Application"
  default     = "django-app"
}

variable "destination_namespace" {
  type        = string
  description = "Namespace, у який Argo CD розгортає застосунок"
  default     = "default"
}

variable "automated_sync" {
  type        = bool
  description = "Автоматична синхронізація змін з Git"
  default     = true
}

variable "self_heal" {
  type        = bool
  description = "Повертати ручні зміни в кластері до стану з Git"
  default     = true
}

variable "prune" {
  type        = bool
  description = "Видаляти ресурси, яких більше немає в Git"
  default     = true
}
