output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "db_endpoint" {
  description = "RDS endpoint (hostname:port)"
  value       = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "RDS hostname"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Database username"
  value       = var.db_username
  sensitive   = true
}

output "db_password_ssm_parameter" {
  description = "SSM parameter name for database password"
  value       = aws_ssm_parameter.db_password.name
}

output "db_username_ssm_parameter" {
  description = "SSM parameter name for database username"
  value       = aws_ssm_parameter.db_username.name
}

output "db_endpoint_ssm_parameter" {
  description = "SSM parameter name for database endpoint"
  value       = aws_ssm_parameter.db_endpoint.name
}

output "db_port_ssm_parameter" {
  description = "SSM parameter name for database port"
  value       = aws_ssm_parameter.db_port.name
}

output "security_group_id" {
  description = "Security group ID attached to RDS"
  value       = aws_security_group.rds.id
}

output "kms_key_arn" {
  description = "ARN of KMS key used for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "kms_key_id" {
  description = "ID of KMS key used for RDS encryption"
  value       = aws_kms_key.rds.key_id
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}

output "parameter_group_name" {
  description = "Database parameter group name"
  value       = aws_db_parameter_group.main.name
}

output "monitoring_role_arn" {
  description = "ARN of monitoring IAM role"
  value       = aws_iam_role.rds_enhanced_monitoring.arn
}

output "backup_retention_period" {
  description = "Backup retention period in days"
  value       = aws_db_instance.main.backup_retention_period
}

output "storage_encrypted" {
  description = "Whether storage encryption is enabled"
  value       = aws_db_instance.main.storage_encrypted
}
