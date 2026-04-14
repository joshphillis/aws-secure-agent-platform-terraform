output "registry_url" {
  description = "ECR registry base URL (e.g., 123456789.dkr.ecr.us-east-1.amazonaws.com)."
  value       = local.registry_url
}

output "repository_urls" {
  description = "Map of repository name to full ECR repository URL."
  value       = { for k, repo in aws_ecr_repository.this : k => repo.repository_url }
}

output "pull_role_arn" {
  description = "ARN of the IAM role for ECS tasks to pull images from ECR."
  value       = aws_iam_role.ecr_pull.arn
}
