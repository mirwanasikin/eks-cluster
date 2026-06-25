# ------------------------------
# Environment Variables
# ------------------------------
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "mirwanasikin-productions"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

# ------------------------------
# Network Variables
# ------------------------------
variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Map for public subnets"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    a = {
      cidr = "10.0.1.0/24"
      az   = "ap-southeast-1a"
    }
    b = {
      cidr = "10.0.2.0/24"
      az   = "ap-southeast-1b"
    }
  }
}

variable "private_subnets" {
  description = "Map for private subnets"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    a = {
      cidr = "10.0.10.0/24"
      az   = "ap-southeast-1a"
    }
    b = {
      cidr = "10.0.11.0/24"
      az   = "ap-southeast-1b"
    }
  }
}

# ------------------------------
# EKS Variables
# ------------------------------
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.33"
}

variable "instance_types" {
  description = "EC2 instance types for node groups"
  type        = list(string)
  default     = ["m7i-flex.large"]
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

# ------------------------------
# Database Variables
# ------------------------------
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "appuser"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

# ------------------------------
# Frontend Variables
# ------------------------------
variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "gitlab_project_path" {
  description = "GitLab project path for OIDC trust policy"
  type        = string
  default     = "mirwanasikin-productions/lab-productions/eks-cluster"
}

variable "enable_origin_shield" {
  description = "Enable AWS Origin Shield for CloudFront"
  type        = bool
  default     = false
}

# ------------------------------
# GitLab OIDC Variables
# ------------------------------
variable "gitlab_url" {
  description = "GitLab instance URL for OIDC configuration"
  type        = string
  default     = "https://gitlab.com"
}

# ------------------------------
# Tags
# ------------------------------
variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
