# ------------------------------
# Security Group for RDS
# ------------------------------
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for RDS database ${var.db_name}"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sg"
  })
}

# ------------------------------
# Inbound Rules - Allow from EKS Nodes Only
# ------------------------------
resource "aws_security_group_rule" "rds_ingress_eks" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.eks_node_security_group_id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow PostgreSQL access from EKS nodes"
}

# ------------------------------
# Security Group Rule Limits (Optional - For RDS Proxy)
# ------------------------------
# resource "aws_security_group" "rds_proxy" {
#   count = var.enable_proxy ? 1 : 0
#   name  = "${local.name_prefix}-proxy-sg"
#   description = "Security group for RDS proxy"
#   vpc_id = var.vpc_id
#
#   tags = merge(local.common_tags, {
#     Name = "${local.name_prefix}-proxy-sg"
#   })
# }
#
# resource "aws_security_group_rule" "rds_proxy_ingress_eks" {
#   count = var.enable_proxy ? 1 : 0
#   type = "ingress"
#   from_port = 5432
#   to_port = 5432
#   protocol = "tcp"
#   source_security_group_id = var.eks_node_security_group_id
#   security_group_id = aws_security_group.rds_proxy[0].id
#   description = "Allow PostgreSQL access from EKS nodes via proxy"
# }
#
# resource "aws_security_group_rule" "rds_proxy_ingress_rds" {
#   count = var.enable_proxy ? 1 : 0
#   type = "ingress"
#   from_port = 5432
#   to_port = 5432
#   protocol = "tcp"
#   source_security_group_id = aws_security_group.rds_proxy[0].id
#   security_group_id = aws_security_group.rds.id
#   description = "Allow RDS proxy to access database"
# }
#
# resource "aws_security_group_rule" "rds_proxy_egress" {
#   count = var.enable_proxy ? 1 : 0
#   type = "egress"
#   from_port = 5432
#   to_port = 5432
#   protocol = "tcp"
#   source_security_group_id = aws_security_group.rds.id
#   security_group_id = aws_security_group.rds_proxy[0].id
#   description = "Allow RDS proxy to egress to database"
# }

