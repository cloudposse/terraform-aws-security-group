output "sg_id" {
  description = "The Security Group ID"
  value       = try(local.sg_id, null)
}

output "sg_arn" {
  description = "The Security Group ARN"
  value       = try(local.sg_arn, null)
}

output "sg_name" {
  description = "The Security Group Name"
  value       = try(local.sg_name, null)
}
