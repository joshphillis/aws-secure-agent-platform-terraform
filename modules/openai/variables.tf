variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC for the Bedrock VPC endpoint and its security group."
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet to place the Bedrock VPC endpoint in (workload subnet)."
}

variable "app_role_name" {
  type        = string
  description = "Name of the IAM role (from the key_vault module) to attach the Bedrock invoke policy to."
}

variable "model_id" {
  type        = string
  description = "Bedrock foundation model ID to invoke (e.g., anthropic.claude-3-haiku-20240307-v1:0)."
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}
