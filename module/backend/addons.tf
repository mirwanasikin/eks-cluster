provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# ------------------------------
# Kubernetes Provider Configuration
# ------------------------------
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
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

  set = [
    {
      name  = "autoDiscovery.clusterName"
      value = aws_eks_cluster.main.name
    },
    {
      name  = "awsRegion"
      value = var.aws_region
    },
    {
      name  = "rbac.serviceAccount.create"
      value = "true"
    },
    {
      name  = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    },
    {
      name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.cluster_autoscaler[0].arn
    },
    {
      name  = "cloudProvider"
      value = "aws"
    }
  ]

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.cluster_autoscaler
  ]
}

# ------------------------------
# Vertical Pod Autoscaler (VPA)
# ------------------------------
resource "aws_eks_addon" "vpa" {
  count = var.enable_vpa ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpa"
  addon_version               = "v1.0.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.common_tags
}

# ------------------------------
# CoreDNS - Managed by EKS, but we ensure it's installed
# ------------------------------
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = "v1.11.1-eksbuild.6"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  #checkov:skip=CKV_AWS_355:CoreDNS required for cluster operations

  tags = local.common_tags
}

# ------------------------------
# kube-proxy
# ------------------------------
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = "v1.30.2-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.common_tags
}
