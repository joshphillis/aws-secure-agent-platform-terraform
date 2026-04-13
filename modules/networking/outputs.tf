output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_name" {
  description = "Name tag of the VPC."
  value       = aws_vpc.this.tags["Name"]
}

output "container_subnet_id" {
  description = "ID of the containers subnet."
  value       = aws_subnet.containers.id
}

output "workload_subnet_id" {
  description = "ID of the optional workload subnet."
  value       = try(aws_subnet.workload[0].id, null)
}
