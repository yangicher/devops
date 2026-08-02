variable "cluster_name" {
  type        = string
  description = "Ім'я EKS кластера"
}

variable "cluster_version" {
  type        = string
  description = "Версія Kubernetes"
  default     = "1.33"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Публічні підмережі (для LoadBalancer сервісів)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Приватні підмережі (для worker nodes)"
}

variable "endpoint_public_access" {
  type        = bool
  description = "Публічний доступ до API кластера (потрібен для kubectl ззовні VPC)"
  default     = true
}

variable "endpoint_private_access" {
  type        = bool
  description = "Приватний доступ до API кластера всередині VPC"
  default     = true
}

variable "enabled_cluster_log_types" {
  type        = list(string)
  description = "Типи логів control plane, які пишуться в CloudWatch"
  default     = ["api", "audit"]
}

variable "node_instance_types" {
  type        = list(string)
  description = "Типи інстансів для worker nodes"
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  type        = string
  description = "ON_DEMAND або SPOT"
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  type        = number
  description = "Розмір диска ноди, GB"
  default     = 20
}

variable "node_desired_size" {
  type        = number
  description = "Бажана кількість нод"
  default     = 2
}

variable "node_min_size" {
  type        = number
  description = "Мінімальна кількість нод"
  default     = 2
}

variable "node_max_size" {
  type        = number
  description = "Максимальна кількість нод"
  default     = 4
}

variable "cluster_addons" {
  type        = list(string)
  description = "Аддони EKS. metrics-server потрібен для роботи HPA"
  default     = ["vpc-cni", "kube-proxy", "coredns", "metrics-server"]
}
