variable "project_name" {
  type        = string
  description = "Short, lowercase platform name (e.g., 'secure-agent')."
}

variable "environment" {
  type        = string
  description = "Environment identifier (dev, prod, etc.)."
}

variable "aws_region" {
  type        = string
  description = "AWS region for all resources (e.g., us-east-1)."
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default     = {}
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "availability_zone" {
  type        = string
  description = "Primary AWS availability zone (e.g., us-east-1a)."
}

variable "availability_zone_b" {
  type        = string
  description = "Secondary AWS availability zone for the ALB's second container subnet (e.g., us-east-1b)."
}

variable "subnet_cidrs" {
  type = object({
    containerapps   = string
    containerapps_b = string
    workload        = string
  })
  description = "CIDR blocks for subnets. containerapps/containerapps_b are the two AZ container subnets required by the ALB; workload hosts the Bedrock VPC endpoint."
}

variable "log_group_name" {
  type        = string
  description = "Optional override for the CloudWatch log group name."
  default     = null
}

variable "secret_prefix" {
  type        = string
  description = "Optional override for the Secrets Manager path prefix (e.g., 'myapp/prod')."
  default     = null
}

variable "model_id" {
  type        = string
  description = "Bedrock foundation model ID to use (e.g., anthropic.claude-3-haiku-20240307-v1:0)."
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
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
  description = "Worker ECS services to deploy."
}