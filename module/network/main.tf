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

# ------------------------------
# Public Subnet
# ------------------------------
resource "aws_subnet" "public" {
  #checkov:skip=CKV_AWS_130:Public IP required for ALB access
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az        # fix typo
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${local.name_prefix}-${each.key}-public-subnet"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"  # fix tag
  }
}

# ------------------------------
# Private Subnet
# ------------------------------
resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az              # fix typo, hapus map_private_ip

  tags = {
    Name                                        = "${local.name_prefix}-${each.key}-private-subnet"
    "kubernetes.io/role/internal-elb"           = "1"       # fix tag
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"  # fix tag
  }
}

# ------------------------------
# Internet Gateway
# ------------------------------
resource "aws_internet_gateway" "main" {                     # fix typo
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
# NAT Gateway — wajib di public subnet!
# ------------------------------
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = values(aws_subnet.public)[0].id  # fix: public bukan private

  tags = {
    Name = "${local.name_prefix}-nat"
  }

  depends_on = [aws_internet_gateway.main]          # fix typo
}

# ------------------------------
# Public Route Table
# ------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id       # fix typo
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
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
    Name = "${local.name_prefix}-private-rt"   # tambah tag
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
