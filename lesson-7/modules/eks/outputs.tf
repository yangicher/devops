output "cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "Ім'я кластера"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "API endpoint кластера"
}

output "cluster_version" {
  value       = aws_eks_cluster.this.version
  description = "Версія Kubernetes"
}

output "cluster_arn" {
  value       = aws_eks_cluster.this.arn
  description = "ARN кластера"
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.this.certificate_authority[0].data
  description = "CA сертифікат кластера (base64)"
}

output "cluster_security_group_id" {
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  description = "Security group, створена EKS для кластера"
}

output "cluster_oidc_issuer_url" {
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
  description = "OIDC issuer URL (для IRSA)"
}

output "node_group_name" {
  value       = aws_eks_node_group.this.node_group_name
  description = "Ім'я групи нод"
}

output "node_role_arn" {
  value       = aws_iam_role.node.arn
  description = "ARN IAM ролі worker nodes"
}
