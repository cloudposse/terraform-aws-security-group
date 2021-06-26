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

output "new_sg_details" {
  description = "Details about the security group created"
  value       = module.new_security_group.security_group_details
}

output "new_sg_rules" {
  description = "Details about all the security group rules created for the existing security group"
  value       = module.new_security_group.rules
}

output "existing_sg_id" {
  description = "The existing Security Group ID"
  value       = module.existing_security_group.id
}

output "existing_sg_arn" {
  description = "The existing Security Group ARN"
  value       = module.existing_security_group.arn
}

output "existing_sg_name" {
  description = "The existing Security Group Name"
  value       = module.existing_security_group.name
}

output "existing_sg_rules" {
  description = "Details about all the security group rules created for the existing security group"
  value       = module.existing_security_group.rules
}

output "disabled_sg_id" {
  description = "The disabled Security Group ID (should be empty)"
  value       = module.disabled_security_group.id == null ? "" : module.disabled_security_group.id
}

output "disabled_sg_arn" {
  description = "The disabled Security Group ARN (should be empty)"
  value       = module.disabled_security_group.arn == null ? "" : module.disabled_security_group.arn
}

output "disabled_sg_name" {
  description = "The disabled Security Group Name (should be empty)"
  value       = module.disabled_security_group.name == null ? "" : module.disabled_security_group.name
}
