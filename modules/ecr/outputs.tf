output "repository_url" {
  value       = aws_ecr_repository.repo.repository_url
  description = "URL репозиторію для docker push"
}

output "repository_name" {
  value       = aws_ecr_repository.repo.name
  description = "Ім'я репозиторію"
}

output "repository_arn" {
  value       = aws_ecr_repository.repo.arn
  description = "ARN репозиторію"
}

output "registry_id" {
  value       = aws_ecr_repository.repo.registry_id
  description = "ID реєстру (AWS account id)"
}
