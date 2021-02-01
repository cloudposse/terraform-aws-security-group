output "id" {
  description = "The Security Group ID"
  value       = try(local.id, null)
}

output "arn" {
  description = "The Security Group ARN"
  value       = try(local.arn, null)
}

output "name" {
  description = "The Security Group Name"
  value       = try(local.name, null)
}
