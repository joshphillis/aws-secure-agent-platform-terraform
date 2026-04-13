output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt secrets."
  value       = aws_kms_key.this.arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key."
  value       = aws_kms_alias.this.name
}

output "secret_prefix" {
  description = "Secrets Manager path prefix for this environment."
  value       = local.name
}

output "role_arn" {
  description = "ARN of the IAM role for apps to assume when reading secrets."
  value       = aws_iam_role.app_role.arn
}

output "role_name" {
  description = "Name of the IAM role for apps (used for attaching additional policies)."
  value       = aws_iam_role.app_role.name
}
