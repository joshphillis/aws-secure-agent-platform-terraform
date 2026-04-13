locals {
  name = coalesce(var.log_group_name, "/aws/${var.project_name}/${var.environment}")
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.name
  retention_in_days = var.retention_in_days

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
