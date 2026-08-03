output "endpoint" {
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
  description = "Хост для підключення (writer endpoint для Aurora)"
}

output "reader_endpoint" {
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : null
  description = "Reader endpoint — тільки для Aurora, для звичайної RDS null"
}

output "port" {
  value       = local.port
  description = "Порт БД"
}

output "connection_string" {
  value       = "${local.is_postgres ? "postgresql" : "mysql"}://${var.username}@${var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address}:${local.port}/${var.db_name}"
  description = "Рядок підключення без пароля"
}

output "database_name" {
  value       = var.db_name
  description = "Ім'я початкової бази даних"
}

output "username" {
  value       = var.username
  description = "Логін master-користувача"
}

output "identifier" {
  value       = var.use_aurora ? aws_rds_cluster.this[0].cluster_identifier : aws_db_instance.this[0].identifier
  description = "Ідентифікатор кластера або інстансу"
}

output "arn" {
  value       = var.use_aurora ? aws_rds_cluster.this[0].arn : aws_db_instance.this[0].arn
  description = "ARN створеної БД"
}

output "is_aurora" {
  value       = var.use_aurora
  description = "Який режим було створено"
}

output "aurora_instance_identifiers" {
  value       = aws_rds_cluster_instance.this[*].identifier
  description = "Ідентифікатори інстансів Aurora-кластера (порожньо для звичайної RDS)"
}

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "ID security group БД"
}

output "subnet_group_name" {
  value       = aws_db_subnet_group.this.name
  description = "Ім'я DB Subnet Group"
}

output "parameter_group_name" {
  value       = aws_db_parameter_group.this.name
  description = "Ім'я parameter group інстансу"
}

output "cluster_parameter_group_name" {
  value       = var.use_aurora ? aws_rds_cluster_parameter_group.this[0].name : null
  description = "Ім'я cluster parameter group (тільки для Aurora)"
}

output "parameter_group_family" {
  value       = local.parameter_group_family
  description = "Родина parameter group, обрана автоматично або задана явно"
}
