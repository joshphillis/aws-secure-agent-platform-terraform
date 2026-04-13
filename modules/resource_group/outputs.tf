output "name" {
  description = "The name of the resource group."
  value       = aws_resourcegroups_group.this.name
}

output "arn" {
  description = "The ARN of the resource group."
  value       = aws_resourcegroups_group.this.arn
}
