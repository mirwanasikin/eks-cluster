data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
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
