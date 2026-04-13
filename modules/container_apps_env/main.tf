locals {
  name = "${var.project_name}-${var.environment}"
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# Private DNS namespace for service-to-service discovery (equivalent to Container Apps default_domain)
resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = "${local.name}.local"
  description = "Private DNS namespace for ${local.name} services"
  vpc         = var.vpc_id

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
