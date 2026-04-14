data "aws_region" "current" {}

locals {
  prefix = "${var.project_name}-${var.environment}"
  apps   = { for app in var.apps : app.name => app }
}

# ─── IAM: Task Execution Role (ECS agent — pulls images, writes logs) ──────────

resource "aws_iam_role" "execution" {
  name = "${local.prefix}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "execution_ecr" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "execution_ecr_pull" {
  name = "${local.prefix}-ecr-pull"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRPullFromAccount"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "arn:aws:ecr:${data.aws_region.current.name}:851725205521:repository/*"
      },
      {
        Sid      = "ECRAuthToken"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      }
    ]
  })
}

# ─── Security Groups ────────────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name   = "${local.prefix}-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_security_group" "containers" {
  name   = "${local.prefix}-containers-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "App port from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "App port for inter-container traffic"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    self        = true
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

# ─── Service Discovery ──────────────────────────────────────────────────────────

resource "aws_service_discovery_service" "apps" {
  for_each = local.apps

  name = each.key

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

resource "aws_service_discovery_service" "orchestrator" {
  name = "orchestrator"

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

# ─── Worker Task Definitions & Services ─────────────────────────────────────────

resource "aws_ecs_task_definition" "apps" {
  for_each = local.apps

  family                   = "${local.prefix}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = var.app_role_arn

  container_definitions = jsonencode([{
    name  = each.key
    image = each.value.image

    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]

    environment = concat(
      [for k, v in each.value.env : { name = k, value = v }],
      [
        { name = "BEDROCK_ENDPOINT", value = var.bedrock_endpoint },
        { name = "BEDROCK_MODEL_ID", value = var.model_id }
      ]
    )

    secrets = [
      for k, v in each.value.secrets : { name = k, valueFrom = v }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = each.key
      }
    }
  }])
}

resource "aws_ecs_service" "apps" {
  for_each = local.apps

  name            = "${local.prefix}-${each.key}"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.apps[each.key].arn
  desired_count   = each.value.min_replicas
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.containers.id]
    assign_public_ip = true # set false when using private subnets with NAT/VPC endpoints
  }

  service_registries {
    registry_arn = aws_service_discovery_service.apps[each.key].arn
  }
}

resource "aws_appautoscaling_target" "apps" {
  for_each = local.apps

  max_capacity       = each.value.max_replicas
  min_capacity       = each.value.min_replicas
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.apps[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "apps_cpu" {
  for_each = local.apps

  name               = "${local.prefix}-${each.key}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.apps[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.apps[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.apps[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# ─── Orchestrator ALB ───────────────────────────────────────────────────────────

resource "aws_lb" "orchestrator" {
  name               = "${local.prefix}-orch-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "orchestrator" {
  name        = "${local.prefix}-orch-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_listener" "orchestrator" {
  load_balancer_arn = aws_lb.orchestrator.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.orchestrator.arn
  }
}

# ─── Orchestrator Task Definition & Service ─────────────────────────────────────

resource "aws_ecs_task_definition" "orchestrator" {
  family                   = "${local.prefix}-orchestrator"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = var.app_role_arn

  container_definitions = jsonencode([{
    name    = "orchestrator"
    image   = var.orchestrator_image
    command = ["./start.sh"]

    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]

    environment = [
      { name = "BEDROCK_ENDPOINT", value = var.bedrock_endpoint },
      { name = "BEDROCK_MODEL_ID", value = var.model_id },
      { name = "WORKER_BASE",      value = local.prefix },
      { name = "NAMESPACE_NAME",   value = var.namespace_name }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "orchestrator"
      }
    }
  }])
}

resource "aws_ecs_service" "orchestrator" {
  name            = "${local.prefix}-orchestrator"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.orchestrator.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.containers.id]
    assign_public_ip = true # set false when using private subnets with NAT/VPC endpoints
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.orchestrator.arn
    container_name   = "orchestrator"
    container_port   = 8000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.orchestrator.arn
  }

  depends_on = [aws_lb_listener.orchestrator]
}
