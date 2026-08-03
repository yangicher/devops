output "bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "Ім'я S3 бакета зі стейтом"
}

output "bucket_url" {
  value       = "https://${aws_s3_bucket.terraform_state.bucket_regional_domain_name}"
  description = "URL бакета"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "Ім'я таблиці блокувань"
}
