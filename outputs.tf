output "id" {
  description = "The created Security Group ID"
  value       = try(local.created_security_group.id, null)
}

output "arn" {
  description = "The created Security Group ARN"
  value       = try(local.created_security_group.arn, null)
}

output "name" {
  description = "The created Security Group Name"
  value       = try(local.created_security_group.name, null)
}
