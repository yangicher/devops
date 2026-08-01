output "bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
}

output "bucket_url" {
  value       = "https://${aws_s3_bucket.terraform_state.bucket_regional_domain_name}"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
}