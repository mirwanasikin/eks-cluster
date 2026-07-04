# ------------------------------
# Environment Configuration
# ------------------------------
environment  = "dev"
project_name = "eks-cluster"
aws_region   = "ap-southeast-1"

# ------------------------------
# Network Configuration
# ------------------------------
vpc_cidr = "10.0.0.0/16"

public_subnets = {
  a = {
    cidr = "10.0.1.0/24"
    az   = "ap-southeast-1a"
  }
  b = {
    cidr = "10.0.2.0/24"
    az   = "ap-southeast-1b"
  }
}

private_subnets = {
  a = {
    cidr = "10.0.10.0/24"
    az   = "ap-southeast-1a"
  }
  b = {
    cidr = "10.0.11.0/24"
    az   = "ap-southeast-1b"
  }
}

# ------------------------------
# EKS Configuration
# ------------------------------
acm_certificate_arn = "arn:aws:acm:us-east-1:419453211849:certificate/3ff896b7-625f-4a7d-b94b-082d652c5419"


# ------------------------------
# EKS Configuration
# ------------------------------
cluster_name            = "eks-cluster"
kubernetes_version      = "1.33"
instance_types          = ["m7i-flex.large"]
desired_capacity        = 2
min_capacity            = 2
max_capacity            = 4
endpoint_private_access = true
endpoint_public_access  = true
enable_vpa              = false

# ------------------------------
# Database Configuration
# ------------------------------
db_name                    = "appdb"
db_username                = "appuser"
db_instance_class          = "db.t3.micro"
db_multi_az                = false
db_backup_retention_period = 1
deletion_protection        = false

# ------------------------------
# Frontend Configuration
# ------------------------------
cloudfront_price_class = "PriceClass_100"
gitlab_project_path    = "mirwanasikin-productions/lab-productions/eks-applications"
enable_origin_shield   = false

# ------------------------------
# GitLab OIDC
# ------------------------------
gitlab_url = "https://gitlab.com"

# ------------------------------
# Tags
# ------------------------------
tags = {
  Environment = "dev"
  Project     = "mirwanasikin-productions"
  ManagedBy   = "opentofu"
  Team        = "platform"
  CostCenter  = "engineering"
}
