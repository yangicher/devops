variable "cluster_name" {
  type        = string
  description = "Ім'я EKS кластера, у який ставиться Jenkins"
}

variable "namespace" {
  type        = string
  description = "Namespace для Jenkins"
  default     = "jenkins"
}

variable "chart_version" {
  type        = string
  description = "Версія Helm-чарта jenkins/jenkins"
  default     = "5.8.18"
}

variable "admin_user" {
  type        = string
  description = "Логін адміністратора Jenkins"
  default     = "admin"
}

variable "admin_password" {
  type        = string
  description = "Пароль адміністратора Jenkins"
  sensitive   = true
}

variable "service_account_name" {
  type        = string
  description = "ServiceAccount, під яким працюють агенти (використовується для IRSA)"
  default     = "jenkins"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN OIDC провайдера кластера"
}

variable "oidc_provider_url" {
  type        = string
  description = "URL OIDC провайдера без схеми"
}

variable "ecr_repository_arn" {
  type        = string
  description = "ARN ECR репозиторію, у який пушить pipeline"
}

variable "storage_class" {
  type        = string
  description = "StorageClass для PVC контролера"
  default     = "gp3"
}

variable "storage_size" {
  type        = string
  description = "Розмір тому Jenkins"
  default     = "8Gi"
}

variable "controller_resources" {
  type = object({
    requests = object({ cpu = string, memory = string })
    limits   = object({ cpu = string, memory = string })
  })
  description = "Ресурси контролера Jenkins"
  default = {
    requests = { cpu = "500m", memory = "1Gi" }
    limits   = { cpu = "1500m", memory = "2Gi" }
  }
}

variable "github_repo_url" {
  type        = string
  description = "HTTPS URL репозиторію, з якого Jenkins бере Jenkinsfile"
}

variable "github_username" {
  type        = string
  description = "Користувач GitHub для push у main"
}

variable "github_token" {
  type        = string
  description = "GitHub Personal Access Token з правом запису в репозиторій"
  sensitive   = true
}

variable "ecr_repository_url" {
  type        = string
  description = "URL ECR репозиторію (передається в pipeline)"
}

variable "aws_region" {
  type        = string
  description = "Регіон AWS"
}

variable "values_file_path" {
  type        = string
  description = "Шлях у репозиторії до values.yaml, у якому оновлюється тег образу"
}

variable "git_branch" {
  type        = string
  description = "Гілка, у яку pipeline пушить оновлений тег"
  default     = "main"
}
