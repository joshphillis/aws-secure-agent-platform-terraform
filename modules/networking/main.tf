resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_subnet" "containers" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidrs.containerapps
  availability_zone = var.availability_zone

  tags = {
    Name        = "${var.project_name}-${var.environment}-snet-containers"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_subnet" "containers_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidrs.containerapps_b
  availability_zone = var.availability_zone_b

  tags = {
    Name        = "${var.project_name}-${var.environment}-snet-containers-b"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ─── Internet Gateway ───────────────────────────────────────────────────────────

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ─── Public Route Table (shared by both container subnets) ──────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rt-public"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_route_table_association" "containers" {
  subnet_id      = aws_subnet.containers.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "containers_b" {
  subnet_id      = aws_subnet.containers_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "workload" {
  count             = var.subnet_cidrs.workload != null ? 1 : 0
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidrs.workload
  availability_zone = var.availability_zone

  tags = {
    Name        = "${var.project_name}-${var.environment}-snet-workload"
    Project     = var.project_name
    Environment = var.environment
  }
}
