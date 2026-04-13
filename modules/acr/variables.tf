variable "project_name" {
  type        = string
  description = "Short, lowercase platform name (e.g., 'secure-agent')."
}

variable "environment" {
  type        = string
  description = "Environment identifier (dev, prod, etc.)."
}

variable "repository_name" {
  type        = string
  description = "Optional override for the ECR repository name."
  default     = null
}
