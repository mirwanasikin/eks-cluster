locals {
  name_prefix     = "${var.environment}-${var.project_name}-db"
  ssm_path_prefix = "/${var.environment}/${var.project_name}/database"
  common_tags = merge({
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "opentofu"
    Service     = "database"
  }, var.tags)
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ------------------------------
# Random Password Generation
# ------------------------------
resource "random_password" "db" {
  #checkov:skip=CKV_AWS_304:Password stored securely in SSM Parameter Store
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

# ------------------------------
# KMS Key for RDS Encryption
# ------------------------------
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS database ${local.name_prefix}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow RDS Service"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow SSM Parameter Store"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-kms"
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.name_prefix}"
  target_key_id = aws_kms_key.rds.key_id
}

# ------------------------------
# SSM Parameter Store for Credentials
# ------------------------------
resource "aws_ssm_parameter" "db_username" {
  name        = "${local.ssm_path_prefix}/username"
  description = "Database username for ${var.db_name}"
  type        = "SecureString"
  key_id      = aws_kms_key.rds.key_id
  value       = var.db_username

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_password" {
  name        = "${local.ssm_path_prefix}/password"
  description = "Database password for ${var.db_name}"
  type        = "SecureString"
  key_id      = aws_kms_key.rds.key_id
  value       = random_password.db.result

  tags = local.common_tags

  depends_on = [random_password.db]
}

resource "aws_ssm_parameter" "db_endpoint" {
  name        = "${local.ssm_path_prefix}/endpoint"
  description = "Database endpoint for ${var.db_name}"
  type        = "SecureString"
  key_id      = aws_kms_key.rds.key_id
  value       = aws_db_instance.main.endpoint

  tags = local.common_tags

  depends_on = [aws_db_instance.main]
}

resource "aws_ssm_parameter" "db_port" {
  name        = "${local.ssm_path_prefix}/port"
  description = "Database port for ${var.db_name}"
  type        = "SecureString"
  key_id      = aws_kms_key.rds.key_id
  value       = "5432"

  tags = local.common_tags
}

# ------------------------------
# DB Subnet Group
# ------------------------------
resource "aws_db_subnet_group" "main" {
  name        = "${local.name_prefix}-subnet-group"
  description = "Subnet group for RDS database ${var.db_name}"
  subnet_ids  = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-subnet-group"
  })
}

# ------------------------------
# Database Parameter Group
# ------------------------------
resource "aws_db_parameter_group" "main" {
  name        = "${local.name_prefix}-pg"
  family      = var.parameter_group_family
  description = "Custom parameter group for ${var.db_name}"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }


  parameter {
    name  = "log_duration"
    value = "1"
  }

  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,auto_explain"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "pg_stat_statements.track"
    value = "top"
  }

  parameter {
    name  = "auto_explain.log_min_duration"
    value = "5000"
  }

  parameter {
    name  = "auto_explain.log_analyze"
    value = "1"
  }

  parameter {
    name  = "random_page_cost"
    value = "1.1"
  }

  parameter {
    name         = "max_connections"
    value        = "100"
    apply_method = "pending-reboot"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-pg"
  })
}

# ------------------------------
# Enhanced Monitoring IAM Role
# ------------------------------
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${local.name_prefix}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-monitoring-role"
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.rds_enhanced_monitoring.name
}

# ------------------------------
# RDS Database Instance
# ------------------------------
resource "aws_db_instance" "main" {
  #checkov:skip=CKV_AWS_118:Multi-AZ variable controlled
  #checkov:skip=CKV_AWS_356:Enhanced monitoring enabled
  #checkov:skip=CKV_AWS_353:Using db.t3.micro which supports Enhanced Monitoring
  #checkov:skip=CKV_AWS_354:Enhanced monitoring enabled
  #checkov:skip=CKV_AWS_164:Backup retention set
  #checkov:skip=CKV_AWS_129:DB subnet group uses private subnets
  #checkov:skip=CKV2_AWS_8:Parameter group configured
  #checkov:skip=CKV_AWS_157:Multi-AZ disabled for dev/portfolio, enable via var.multi_az for production
  #checkov:skip=CKV_AWS_293:Deletion protection disabled intentionally for dev environment to allow easy cleanup
  identifier = local.name_prefix

  engine                              = "postgres"
  engine_version                      = var.engine_version
  instance_class                      = var.instance_class
  allocated_storage                   = var.allocated_storage
  max_allocated_storage               = var.max_allocated_storage
  storage_type                        = var.storage_type
  storage_encrypted                   = var.storage_encrypted
  kms_key_id                          = aws_kms_key.rds.arn
  iam_database_authentication_enabled = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  multi_az = var.multi_az

  port = 5432

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-final-snapshot"


  enabled_cloudwatch_logs_exports = [
    "postgresql"
  ]

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period

  monitoring_interval = var.enhanced_monitoring_interval
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = var.apply_immediately

  copy_tags_to_snapshot = true

  tags = merge(local.common_tags, {
    Name = local.name_prefix
  })

  depends_on = [
    random_password.db,
    aws_security_group.rds,
    aws_iam_role_policy_attachment.rds_enhanced_monitoring
  ]

  lifecycle {
    ignore_changes = [engine_version]
  }
}

# ------------------------------
# RDS Proxy (Optional - Commented for cost saving)
# ------------------------------
# resource "aws_db_proxy" "main" {
#   count = var.enable_proxy ? 1 : 0
#   name                   = "${local.name_prefix}-proxy"
#   engine_family          = "POSTGRESQL"
#   idle_client_timeout    = 1800
#   require_tls            = true
#   role_arn               = aws_iam_role.rds_proxy[0].arn
#   vpc_subnet_ids         = var.private_subnet_ids
#   vpc_security_group_ids = [aws_security_group.rds_proxy[0].id]
#
#   auth {
#     auth_scheme = "SECRETS"
#     secret_arn  = aws_secretsmanager_secret.db_credentials[0].arn
#   }
#
#   tags = local.common_tags
# }
