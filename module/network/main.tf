locals {
  name_prefix = "${var.environment}-eks-network"
}

# ------------------------------
# VPC
# ------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
}

resource "aws_cloudwatch_log_group" "flow_log" {
  name              = "/aws/vpc/${local.name_prefix}-flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.flow_log.arn

  #checkov:skip=CKV_AWS_338:Retention set to 1 year
}

resource "aws_kms_key" "flow_log" {
  description             = "KMS key for VPC flow logs"
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
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
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

  tags = {
    Name = "${local.name_prefix}-flow-log-kms"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "flow_log" {
  name = "${local.name_prefix}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "flow_log" {
  role       = aws_iam_role.flow_log.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-default-sg"
  }
}

# ------------------------------
# Public Subnet
# ------------------------------
resource "aws_subnet" "public" {
  #checkov:skip=CKV_AWS_130:Public IP required for ALB access
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name                                                           = "${local.name_prefix}-${each.key}-public-subnet"
    "kubernetes.io/role/elb"                                       = "1"
    "kubernetes.io/cluster/${var.environment}-${var.cluster_name}" = "shared"
  }
}

# ------------------------------
# Private Subnet
# ------------------------------
resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name                                                           = "${local.name_prefix}-${each.key}-private-subnet"
    "kubernetes.io/role/internal-elb"                              = "1"
    "kubernetes.io/cluster/${var.environment}-${var.cluster_name}" = "shared"
  }
}

# ------------------------------
# Internet Gateway
# ------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# ------------------------------
# Elastic IP
# ------------------------------
resource "aws_eip" "main" {
  #checkov:skip=CKV2_AWS_19:EIP attached to NAT Gateway, not a loose EIP
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-eip"
  }
}

# ------------------------------
# NAT Gateway
# ------------------------------
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = values(aws_subnet.public)[0].id

  tags = {
    Name = "${local.name_prefix}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# ------------------------------
# Public Route Table
# ------------------------------
resource "aws_route_table" "public" {
  #checkov:skip=CKV2_AWS_35:IGW route required for public subnet
  #checkov:skip=CKV2_AWS_44:No VPC peering in us
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  #checkov:skip=CKV2_AWS_35:NAT Gateway route for private subnet
  #checkov:skip=CKV2_AWS_44:No VPC peering in use
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------
# Private Route Table
# ------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-private-route-table"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# ------------------------------
# VPC Endpoint for SSM (Interface)
# ------------------------------
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-ssm-endpoint"
  }
}

# ------------------------------
# VPC Endpoint for SSM Messages (Interface)
# ------------------------------
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-ssmmessages-endpoint"
  }
}

# ------------------------------
# VPC Endpoint for EC2 Messages (Interface)
# ------------------------------
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-ec2messages-endpoint"
  }
}

# ------------------------------
# VPC Endpoint for S3 (Gateway)
# ------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id, aws_route_table.public.id]

  tags = {
    Name = "${local.name_prefix}-s3-endpoint"
  }
}

# ------------------------------
# VPC Endpoint for KMS (Interface)
# ------------------------------
resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-kms-endpoint"
  }
}

# ------------------------------
# VPC Endpoint for CloudWatch Logs (Interface)
# ------------------------------
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-logs-endpoint"
  }
}

# ------------------------------
# Security Group for VPC Endpoints
# ------------------------------
resource "aws_security_group" "vpc_endpoints" {
  #checkov:skip=CKV_AWS_382:Egress is allowed for all traffic because the VPC Endpoint only accepts inbound traffic from secured VPCs. The risk of data exfiltration is minimal because the endpoint is for managed AWS services (SSM, KMS, etc.).
  name        = "${local.name_prefix}-vpce-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for s in aws_subnet.private : s.cidr_block]
    description = "Allow HTTPS from EKS nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${local.name_prefix}-vpce-sg"
  }
}
