
output "id" {
  description = "The created or target Security Group ID"
  value       = local.security_group_id
}

output "arn" {
  description = "The created Security Group ARN (null if using existing security group)"
  value       = try(local.created_security_group.arn, null)
}

output "name" {
  description = "The created Security Group Name (null if using existing security group)"
  value       = try(local.created_security_group.name, null)
}
