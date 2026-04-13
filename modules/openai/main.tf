data "aws_region" "current" {}

data "aws_vpc" "this" {
  id = var.vpc_id
}

locals {
  name = "${var.project_name}-${var.environment}-bedrock"
}

# ─── Security Group for the Bedrock VPC Endpoint ───────────────────────────────

resource "aws_security_group" "bedrock_endpoint" {
  name   = "${local.name}-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "HTTPS from within the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ─── VPC Interface Endpoint for private Bedrock access ─────────────────────────
# Replaces: azurerm_private_dns_zone + azurerm_private_dns_zone_virtual_network_link
#           + azurerm_private_endpoint
# AWS enables private DNS automatically — no separate zone or VNet link required.
# NOTE: model access must be granted in the AWS Console before invoking models.

resource "aws_vpc_endpoint" "bedrock_runtime" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.bedrock_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "${local.name}-endpoint"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ─── IAM: allow the app role to invoke the configured Bedrock model ─────────────
# Replaces: azurerm_cognitive_account API-key auth

resource "aws_iam_role_policy" "bedrock_invoke" {
  name = "${local.name}-invoke"
  role = var.app_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ]
      Resource = "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/${var.model_id}"
    }]
  })
}
