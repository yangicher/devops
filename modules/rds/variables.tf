variable "use_aurora" {
  type        = bool
  description = "true — створити Aurora Cluster з writer-інстансами; false — одну звичайну RDS instance"
  default     = false
}

variable "name" {
  type        = string
  description = "Базове ім'я, з якого формуються імена всіх ресурсів модуля"
}

variable "engine" {
  type        = string
  description = "Рушій БД: postgres, mysql, aurora-postgresql або aurora-mysql"
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql", "aurora-postgresql", "aurora-mysql"], var.engine)
    error_message = "engine має бути одним з: postgres, mysql, aurora-postgresql, aurora-mysql."
  }
}

variable "engine_version" {
  type        = string
  description = "Версія рушія, наприклад 16.4 для postgres або 8.0.39 для mysql"
  default     = "16.4"
}

variable "instance_class" {
  type        = string
  description = "Клас інстансу. Для Aurora мінімум db.t3.medium; db.t4g.micro підходить для звичайної RDS"
  default     = "db.t4g.micro"
}

variable "multi_az" {
  type        = bool
  description = "Розгортати standby в іншій зоні доступності (тільки для звичайної RDS)"
  default     = false
}

variable "aurora_instance_count" {
  type        = number
  description = "Кількість інстансів в Aurora-кластері: перший writer, решта reader"
  default     = 1

  validation {
    condition     = var.aurora_instance_count >= 1 && var.aurora_instance_count <= 15
    error_message = "aurora_instance_count має бути в межах 1..15."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC, у якій створюється security group"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Підмережі для DB Subnet Group (мінімум дві в різних AZ)"

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Потрібно щонайменше дві підмережі в різних зонах доступності."
  }
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR-блоки, яким дозволено підключатись до БД"
  default     = []
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security groups, яким дозволено підключатись до БД (наприклад SG нод EKS)"
  default     = []
}

variable "db_name" {
  type        = string
  description = "Ім'я початкової бази даних"
  default     = "appdb"
}

variable "username" {
  type        = string
  description = "Логін master-користувача"
  default     = "dbadmin"
}

variable "password" {
  type        = string
  description = "Пароль master-користувача (мінімум 8 символів)"
  sensitive   = true
}

variable "port" {
  type        = number
  description = "Порт БД. null — взяти типовий для рушія (5432 або 3306)"
  default     = null
}

variable "allocated_storage" {
  type        = number
  description = "Розмір диска в GB (ігнорується для Aurora — там сховище росте автоматично)"
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Верхня межа автоскейлінгу диска в GB; 0 — вимкнути автоскейлінг"
  default     = 100
}

variable "storage_type" {
  type        = string
  description = "Тип диска для звичайної RDS: gp2, gp3, io1"
  default     = "gp3"
}

variable "storage_encrypted" {
  type        = bool
  description = "Шифрувати сховище"
  default     = true
}

variable "kms_key_id" {
  type        = string
  description = "ARN KMS-ключа; null — використати ключ AWS за замовчуванням"
  default     = null
}

variable "parameter_group_family" {
  type        = string
  description = "Родина parameter group, наприклад postgres16. Порожній рядок — визначити автоматично з engine і engine_version"
  default     = ""
}

variable "parameters" {
  type = map(object({
    value        = string
    apply_method = optional(string, "immediate")
  }))
  description = "Параметри БД, які перевизначають або доповнюють базовий набір (max_connections, log_statement, work_mem)"
  default     = {}
}

variable "backup_retention_period" {
  type        = number
  description = "Скільки днів зберігати автоматичні бекапи"
  default     = 7
}

variable "backup_window" {
  type        = string
  description = "Вікно бекапів у UTC, формат hh24:mi-hh24:mi"
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  type        = string
  description = "Вікно обслуговування, формат ddd:hh24:mi-ddd:hh24:mi"
  default     = "sun:04:30-sun:05:30"
}

variable "deletion_protection" {
  type        = bool
  description = "Заборонити видалення БД через API"
  default     = false
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Не робити фінальний снапшот при видаленні (true зручно для навчальних середовищ)"
  default     = true
}

variable "publicly_accessible" {
  type        = bool
  description = "Видати БД публічний IP"
  default     = false
}

variable "performance_insights_enabled" {
  type        = bool
  description = "Увімкнути Performance Insights"
  default     = false
}

variable "monitoring_interval" {
  type        = number
  description = "Інтервал Enhanced Monitoring у секундах: 0, 1, 5, 10, 15, 30 або 60. Ненульове значення вимагає monitoring_role_arn"
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval має бути одним з: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "monitoring_role_arn" {
  type        = string
  description = "ARN IAM-ролі для Enhanced Monitoring. Обов'язковий, якщо monitoring_interval > 0"
  default     = null

  validation {
    condition     = var.monitoring_interval == 0 || var.monitoring_role_arn != null
    error_message = "При monitoring_interval > 0 потрібно задати monitoring_role_arn."
  }
}

variable "apply_immediately" {
  type        = bool
  description = "Застосовувати зміни одразу, не чекаючи вікна обслуговування"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Додаткові теги для всіх ресурсів модуля"
  default     = {}
}
