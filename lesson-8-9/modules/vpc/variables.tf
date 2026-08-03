variable "vpc_name" {
  type        = string
  description = "Ім'я VPC (використовується як префікс для тегів)"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR блок VPC"
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR блоки публічних підмереж"
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR блоки приватних підмереж"
}

variable "availability_zones" {
  type        = list(string)
  description = "Зони доступності для підмереж"
}

variable "cluster_name" {
  type        = string
  description = "Ім'я EKS кластера для тегування підмереж (порожнє — теги не додаються)"
  default     = ""
}
