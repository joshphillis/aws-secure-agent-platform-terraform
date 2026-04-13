output "registry_url" {
  description = "ECR registry base URL (e.g., 123456789.dkr.ecr.us-east-1.amazonaws.com)."
  value       = local.registry_url
}

output "repository_url" {
  description = "Full ECR repository URL including the repository name."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "pull_role_arn" {
  description = "ARN of the IAM role for ECS tasks to pull images from ECR."
  value       = aws_iam_role.ecr_pull.arn
}
