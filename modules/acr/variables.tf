variable "project_name" {
  type        = string
  description = "Short, lowercase platform name (e.g., 'secure-agent')."
}

variable "environment" {
  type        = string
  description = "Environment identifier (dev, prod, etc.)."
}

variable "repository_names" {
  type        = list(string)
  description = "List of ECR repository names to create — one per worker plus orchestrator."
}
