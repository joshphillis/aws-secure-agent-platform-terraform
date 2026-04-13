output "cluster_id" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "namespace_id" {
  description = "ID of the Cloud Map private DNS namespace."
  value       = aws_service_discovery_private_dns_namespace.this.id
}

output "namespace_name" {
  description = "DNS name of the private namespace for service discovery (e.g., secure-agent.dev.local)."
  value       = aws_service_discovery_private_dns_namespace.this.name
}
