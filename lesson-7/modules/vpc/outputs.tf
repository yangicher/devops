output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID VPC"
}

output "vpc_cidr_block" {
  value       = aws_vpc.main.cidr_block
  description = "CIDR блок VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "ID публічних підмереж"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "ID приватних підмереж"
}
