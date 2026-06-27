output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_security_group.eks_nodes.id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for EKS cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "ARN of OIDC provider for EKS cluster"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of OIDC provider for EKS cluster"
  value       = aws_iam_openid_connect_provider.eks.url
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.main.id
}

output "kms_key_arn" {
  description = "ARN of KMS key used for EKS secret encryption"
  value       = aws_kms_key.eks.arn
}

output "cluster_iam_role_arn" {
  description = "ARN of EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "nodes_iam_role_arn" {
  description = "ARN of EKS nodes IAM role"
  value       = aws_iam_role.eks_nodes.arn
}

output "cluster_autoscaler_iam_role_arn" {
  description = "ARN of cluster autoscaler IAM role"
  value       = aws_iam_role.cluster_autoscaler.arn
}
