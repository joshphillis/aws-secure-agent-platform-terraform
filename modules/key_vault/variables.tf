variable "project_name" {
  type        = string
  description = "Short, lowercase platform name (e.g., 'secure-agent')."
}

variable "environment" {
  type        = string
  description = "Environment identifier (dev, prod, etc.)."
}

variable "secret_prefix" {
  type        = string
  description = "Optional override for the Secrets Manager path prefix (e.g., 'myapp/prod')."
  default     = null
}
