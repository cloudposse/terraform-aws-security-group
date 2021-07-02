output "created_sg_id" {
  description = "The new one Security Group ID"
  value       = module.new_security_group.id
}

output "created_sg_arn" {
  description = "The new one Security Group ARN"
  value       = module.new_security_group.arn
}

output "created_sg_name" {
  description = "The new one Security Group Name"
  value       = module.new_security_group.name
}
