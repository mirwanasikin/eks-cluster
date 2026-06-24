# ------------------------------
# Security Group Rules - Cluster
# ------------------------------
resource "aws_security_group_rule" "cluster_ingress_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow nodes to communicate with cluster API"
}

resource "aws_security_group_rule" "nodes_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow HTTPS outbound for AWS APIs and ECR"
}

resource "aws_security_group_rule" "nodes_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow HTTP outbound"
}

# ------------------------------
# Security Group Rules - Nodes
# ------------------------------
resource "aws_security_group_rule" "nodes_ingress_cluster" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.eks_nodes.id
  description              = "Allow cluster to communicate with kubelet"
}

resource "aws_security_group_rule" "nodes_ingress_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.eks_nodes.id
  description              = "Allow nodes to communicate with each other"
}

