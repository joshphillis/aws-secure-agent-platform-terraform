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
  description = "AWS availability zone for subnets (e.g., us-east-1a)."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "subnet_cidrs" {
  type = object({
    containerapps = string
    workload      = optional(string)
  })
  description = "CIDR blocks for subnets."
}
