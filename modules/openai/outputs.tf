output "endpoint" {
  description = "Bedrock runtime HTTPS endpoint. Resolves privately via the VPC endpoint when private_dns_enabled = true."
  value       = "https://bedrock-runtime.${data.aws_region.current.name}.amazonaws.com"
}

output "model_id" {
  description = "Bedrock foundation model ID configured for this environment."
  value       = var.model_id
}

output "vpc_endpoint_id" {
  description = "ID of the Bedrock runtime VPC interface endpoint."
  value       = aws_vpc_endpoint.bedrock_runtime.id
}
