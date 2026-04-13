variable "project_name" {
  type        = string
  description = "Short, lowercase platform name (e.g., 'secure-agent')."
}

variable "environment" {
  type        = string
  description = "Environment identifier (dev, prod, etc.)."
}

variable "log_group_name" {
  type        = string
  description = "Optional override for the CloudWatch log group name."
  default     = null
}

variable "retention_in_days" {
  type        = number
  description = "Retention period for logs in days."
  default     = 30
}
