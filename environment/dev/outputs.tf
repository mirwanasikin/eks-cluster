# ------------------------------
# Network Outputs
# ------------------------------
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = var.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.network.private_subnet_ids
}

# ------------------------------
# EKS Outputs
# ------------------------------
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.backend.cluster_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.backend.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.backend.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.backend.cluster_endpoint
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.backend.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.backend.node_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for EKS cluster"
  value       = module.backend.cluster_certificate_authority_data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN of OIDC provider for EKS cluster"
  value       = module.backend.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of OIDC provider for EKS cluster"
  value       = module.backend.oidc_provider_url
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = module.backend.node_group_id
}

output "cluster_iam_role_arn" {
  description = "ARN of EKS cluster IAM role"
  value       = module.backend.cluster_iam_role_arn
}

output "nodes_iam_role_arn" {
  description = "ARN of EKS nodes IAM role"
  value       = module.backend.nodes_iam_role_arn
}

# ------------------------------
# Database Outputs
# ------------------------------
output "db_instance_id" {
  description = "RDS instance ID"
  value       = module.database.db_instance_id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = module.database.db_instance_arn
}

output "db_endpoint" {
  description = "RDS endpoint (hostname:port)"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "db_address" {
  description = "RDS hostname"
  value       = module.database.db_address
  sensitive   = true
}

output "db_port" {
  description = "RDS port"
  value       = module.database.db_port
}

output "db_name" {
  description = "Database name"
  value       = module.database.db_name
}

output "db_username_ssm_parameter" {
  description = "SSM parameter name for database username"
  value       = module.database.db_username_ssm_parameter
  sensitive   = true
}

output "db_password_ssm_parameter" {
  description = "SSM parameter name for database password"
  value       = module.database.db_password_ssm_parameter
  sensitive   = true
}

output "db_endpoint_ssm_parameter" {
  description = "SSM parameter name for database endpoint"
  value       = module.database.db_endpoint_ssm_parameter
  sensitive   = true
}

output "db_port_ssm_parameter" {
  description = "SSM parameter name for database port"
  value       = module.database.db_port_ssm_parameter
  sensitive   = true
}

output "database_security_group_id" {
  description = "Security group ID attached to RDS"
  value       = module.database.security_group_id
}

output "database_kms_key_arn" {
  description = "ARN of KMS key used for RDS encryption"
  value       = module.database.kms_key_arn
}

# ------------------------------
# Frontend Outputs
# ------------------------------
output "frontend_bucket_id" {
  description = "S3 bucket ID for frontend"
  value       = module.frontend.bucket_id
}

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = module.frontend.bucket_name
}

output "frontend_bucket_arn" {
  description = "S3 bucket ARN for frontend"
  value       = module.frontend.bucket_arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.frontend.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = module.frontend.cloudfront_distribution_arn
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name for frontend"
  value       = module.frontend.cloudfront_domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID for Route53 alias records"
  value       = module.frontend.cloudfront_hosted_zone_id
}

output "gitlab_ci_role_arn" {
  description = "ARN of the IAM role for GitLab CI"
  value       = module.frontend.gitlab_ci_role_arn
}

output "gitlab_ci_role_name" {
  description = "Name of the IAM role for GitLab CI"
  value       = module.frontend.gitlab_ci_role_name
}

output "frontend_kms_key_arn" {
  description = "ARN of KMS key used for S3 encryption"
  value       = module.frontend.kms_key_arn
}

# ------------------------------
# Combined Outputs for Operational Use
# ------------------------------
output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for service account IAM roles"
  value       = module.backend.oidc_provider_url
}

output "ssm_database_path_prefix" {
  description = "SSM parameter store path prefix for database credentials"
  value       = "/${var.environment}/${var.project_name}/database"
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

# ------------------------------
# Kubernetes Configuration Outputs
# ------------------------------
output "kubeconfig_commands" {
  description = "Commands to configure kubectl"
  value = {
    update_kubeconfig = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.backend.cluster_name}"
    get_nodes         = "kubectl get nodes"
  }
}
