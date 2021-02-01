output "new_sg_id" {
  description = "The new one Security Group ID"
  value       = module.new_security_group.id
}

output "new_sg_arn" {
  description = "The new one Security Group ARN"
  value       = module.new_security_group.arn
}

output "new_sg_name" {
  description = "The new one Security Group Name"
  value       = module.new_security_group.name
}

output "external_sg_id" {
  description = "The external Security Group ID"
  value       = module.external_security_group.id
}

output "external_sg_arn" {
  description = "The external Security Group ARN"
  value       = module.external_security_group.arn
}

output "external_sg_name" {
  description = "The external Security Group Name"
  value       = module.external_security_group.name
}

output "disabled_sg_id" {
  description = "The disabled Security Group ID (should be empty)"
  value       = module.disabled_security_group.id
}

output "disabled_sg_arn" {
  description = "The disabled Security Group ARN (should be empty)"
  value       = module.disabled_security_group.arn
}

output "disabled_sg_name" {
  description = "The disabled Security Group Name (should be empty)"
  value       = module.disabled_security_group.name
}
