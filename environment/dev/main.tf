# ------------------------------
# Provider Configuration
# ------------------------------
terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }

}

provider "aws" {
  region = var.aws_region

  # Tags will be applied to all resources
  default_tags {
    tags = merge({
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "opentofu"
    }, var.tags)
  }
}

provider "helm" {
  kubernetes {
    host                   = module.backend.cluster_endpoint
    cluster_ca_certificate = base64decode(module.backend.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

provider "kubernetes" {
  host                   = module.backend.cluster_endpoint
  cluster_ca_certificate = base64decode(module.backend.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.main.token
}


# ------------------------------
# Local Variables
# ------------------------------
locals {
  name_prefix = "${var.environment}-${var.project_name}"
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "opentofu"
  }
}

# ------------------------------
# Module: Network
# ------------------------------
module "network" {
  source = "../../module/network"

  environment     = var.environment
  cluster_name    = var.cluster_name
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  aws_region      = var.aws_region
}

# ------------------------------
# Module: EKS Backend
# ------------------------------
module "backend" {
  source = "../../module/backend"

  environment        = var.environment
  cluster_name       = var.cluster_name
  aws_region         = var.aws_region
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids

  kubernetes_version = var.kubernetes_version
  instance_types     = var.instance_types
  desired_capacity   = var.desired_capacity
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity

  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access


  tags = var.tags

  depends_on = [module.network]
}

# ------------------------------
# Module: Database (RDS)
# ------------------------------
module "database" {
  source = "../../module/database"

  environment                = var.environment
  project_name               = var.project_name
  aws_region                 = var.aws_region
  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  eks_node_security_group_id = module.backend.node_security_group_id

  db_name                 = var.db_name
  db_username             = var.db_username
  instance_class          = var.db_instance_class
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period

  # Additional security - enable deletion protection
  deletion_protection = true
  skip_final_snapshot = false

  # Performance Insights for dev
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Enhanced monitoring
  enhanced_monitoring_interval = 60

  tags = var.tags

  depends_on = [module.network, module.backend]
}

# ------------------------------
# Module: Frontend (S3 + CloudFront)
# ------------------------------
module "frontend" {
  source = "../../module/frontend"

  environment            = var.environment
  project_name           = var.project_name
  aws_region             = var.aws_region
  gitlab_url             = var.gitlab_url
  gitlab_project_path    = var.gitlab_project_path
  cloudfront_price_class = var.cloudfront_price_class
  enable_origin_shield   = var.enable_origin_shield

  tags = var.tags

  depends_on = []
}

# ------------------------------
# Data Sources for Cross-module References
# ------------------------------
data "aws_eks_cluster_auth" "main" {
  name       = module.backend.cluster_name
  depends_on = [module.backend]
}

# ------------------------------
# Cluster Autoscaler (Helm)
# ------------------------------
resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.37.0"

  set {
    name  = "autoDiscovery.clusterName"
    value = module.backend.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.backend.cluster_autoscaler_iam_role_arn
  }

  set {
    name  = "cloudProvider"
    value = "aws"
  }

  depends_on = [module.backend]
}
