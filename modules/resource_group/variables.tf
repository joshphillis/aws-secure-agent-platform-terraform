variable "project_name" {
  type        = string
  description = "Short, lowercase name for the platform (e.g., 'secure-agent')."
}

variable "environment" {
  type        = string
  description = "Environment identifier (e.g., dev, prod)."
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default     = {}
}
