variable "project_name" {
  type        = string
  description = "Short, lowercase platform name (e.g., 'secure-agent')."
}

variable "environment" {
  type        = string
  description = "Environment identifier (dev, prod, etc.)."
}

variable "cluster_name" {
  type        = string
  description = "Name of the ECS cluster."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC for security groups and the ALB."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for Fargate tasks and the orchestrator ALB. Provide 2+ subnets in different AZs for production ALB."
}

variable "namespace_id" {
  type        = string
  description = "Cloud Map private DNS namespace ID for service discovery."
}

variable "namespace_name" {
  type        = string
  description = "Cloud Map private DNS namespace name passed to the orchestrator (e.g., secure-agent.dev.local)."
}

variable "app_role_arn" {
  type        = string
  description = "ARN of the IAM task role used by containers at runtime (Secrets Manager access)."
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch log group name for container log output."
}

variable "bedrock_endpoint" {
  type        = string
  description = "Bedrock runtime HTTPS endpoint URL."
}

variable "model_id" {
  type        = string
  description = "Bedrock foundation model ID (e.g., anthropic.claude-3-haiku-20240307-v1:0)."
}

variable "apps" {
  type = list(object({
    name         = string
    image        = string
    cpu          = number       # Fargate CPU units (256, 512, 1024, 2048, 4096)
    memory       = number       # Memory in MiB (512, 1024, 2048, …)
    min_replicas = optional(number, 1)
    max_replicas = optional(number, 3)
    env          = map(string)
    secrets      = map(string)  # map of env-var name → Secrets Manager ARN
  }))
  description = "Worker container services to deploy."
}

variable "orchestrator_image" {
  type        = string
  description = "Full ECR image reference for the orchestrator (e.g., 123.dkr.ecr.us-east-1.amazonaws.com/proj:v7)."
}
