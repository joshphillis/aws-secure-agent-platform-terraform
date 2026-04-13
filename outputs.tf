output "resource_group_name" {
  value = module.resource_group.name
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "ecs_cluster_name" {
  value = module.container_apps_env.cluster_name
}

output "orchestrator_endpoint" {
  description = "Public DNS name of the orchestrator ALB."
  value       = module.container_apps.orchestrator_endpoint
}

output "worker_service_names" {
  value = module.container_apps.worker_service_names
}

output "bedrock_endpoint" {
  description = "Bedrock runtime endpoint used by all ECS services."
  value       = module.openai.endpoint
}

output "bedrock_model_id" {
  description = "Bedrock foundation model ID configured for this environment."
  value       = module.openai.model_id
}
