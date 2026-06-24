locals {
  name_prefix  = "${var.environment}-eks-${var.cluster_name}"
  cluster_name = "${var.environment}-${var.cluster_name}"
  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "opentofu"
    Cluster     = var.cluster_name
  }, var.tags)
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# ------------------------------
# Security Group for EKS
# ------------------------------
resource "aws_security_group" "eks_cluster" {
  name        = "${local.name_prefix}-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cluster-sg"
  })
}

resource "aws_security_group" "eks_nodes" {
  #checkov:skip=CKV2_AWS_5:SG attached to EKS node group, not detected by Checkov static analysis
  name        = "${local.name_prefix}-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nodes-sg"
  })
}

# ------------------------------
# EKS Cluster IAM Role
# ------------------------------
resource "aws_iam_role" "eks_cluster" {
  name = "${local.name_prefix}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_vpc_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# ------------------------------
# EKS Node IAM Role
# ------------------------------
resource "aws_iam_role" "eks_nodes" {
  name = "${local.name_prefix}-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_nodes_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# ------------------------------
# KMS Key for EKS Secret Encryption
# ------------------------------
resource "aws_kms_key" "eks" {
  #checkov:skip=CKV_AWS_7:Key rotation enabled
  description             = "KMS key for EKS cluster ${local.cluster_name}"
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
        Sid    = "Allow EKS Service"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
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

resource "aws_kms_alias" "eks" {
  name          = "alias/${local.name_prefix}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# ------------------------------
# EKS Cluster
# ------------------------------
resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : []
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_cluster_vpc_policy,
  ]

  tags = merge(local.common_tags, {
    Name = local.cluster_name
  })
}

# ------------------------------
# OIDC Provider
# ------------------------------
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = local.common_tags
}

# ------------------------------
# EKS Node Group
# ------------------------------
resource "aws_eks_node_group" "main" {
  #checkov:skip=CKV_AWS_322:Node group uses latest AMI
  #checkov:skip=CKV2_AWS_53:Node group in private subnets
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name_prefix}-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids

  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = var.instance_types

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }


  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_policy,
    aws_iam_role_policy_attachment.eks_nodes_cni_policy,
    aws_iam_role_policy_attachment.eks_nodes_registry_policy,
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-node-group"
  })
}

# ------------------------------
# AWS Auth ConfigMap
# ------------------------------
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = jsonencode([{
      rolearn  = aws_iam_role.eks_nodes.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes"
      ]
    }])
  }

  depends_on = [aws_eks_cluster.main]
}
