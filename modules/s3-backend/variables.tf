variable "bucket_name" {
  type        = string
  description = "Ім'я S3 бакета для збереження стейту"
}

variable "table_name" {
  type        = string
  description = "Ім'я таблиці DynamoDB для блокування"
}
