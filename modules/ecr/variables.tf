variable "ecr_name" {
  type        = string
  description = "Ім'я ECR репозиторію"
}

variable "scan_on_push" {
  type        = bool
  description = "Сканувати образи на вразливості при push"
  default     = true
}

variable "force_delete" {
  type        = bool
  description = "Дозволити видалення репозиторію разом з образами"
  default     = false
}

variable "keep_last_images" {
  type        = number
  description = "Скільки останніх образів зберігати"
  default     = 10
}
