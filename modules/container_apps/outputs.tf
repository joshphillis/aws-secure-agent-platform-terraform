output "orchestrator_endpoint" {
  description = "Public DNS name of the orchestrator ALB."
  value       = aws_lb.orchestrator.dns_name
}

output "worker_service_arns" {
  description = "Map of worker app name to ECS service ARN."
  value       = { for k, v in aws_ecs_service.apps : k => v.id }
}

output "worker_service_names" {
  description = "List of deployed worker ECS service names."
  value       = [for k, v in aws_ecs_service.apps : v.name]
}
