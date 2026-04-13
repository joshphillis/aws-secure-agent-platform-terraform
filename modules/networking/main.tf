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
