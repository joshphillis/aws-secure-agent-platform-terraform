variable "project_name" {
  type        = string
  description = "Short, lowercase platform name (e.g., 'secure-agent')."
}

variable "environment" {
  type        = string
  description = "Environment identifier (dev, prod, etc.)."
}

variable "availability_zone" {
  type        = string
  description = "Primary AWS availability zone (e.g., us-east-1a)."
}

variable "availability_zone_b" {
  type        = string
  description = "Secondary AWS availability zone for the second container subnet (e.g., us-east-1b)."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "subnet_cidrs" {
  type = object({
    containerapps   = string
    containerapps_b = string
    workload        = optional(string)
  })
  description = "CIDR blocks for subnets. containerapps and containerapps_b are placed in separate AZs for ALB multi-AZ support."
}
