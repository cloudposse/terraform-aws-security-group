output "created_sg_id" {
  description = "The ID of the created Security Group"
  value       = module.new_security_group.id
}

output "created_sg_arn" {
  description = "The ARN of the created Security Group"
  value       = module.new_security_group.arn
}

output "created_sg_name" {
  description = "The name of the created Security Group"
  value       = module.new_security_group.name
}

output "test_created_sg_id" {
  description = "The security group created by the test to use as \"target\" security group"
  value       = aws_security_group.target.id
}

output "target_sg_id" {
  description = "The target Security Group ID"
  value       = module.target_security_group.id
}

output "target_sg_arn" {
  description = "The target Security Group ARN"
  value       = module.target_security_group.arn
}

output "target_sg_name" {
  description = "The target Security Group name"
  value       = module.target_security_group.name
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

output "rules_terraform_ids" {
  description = "List of Terraform IDs of created `security_group_rule` resources"
  value       = module.new_security_group.rules_terraform_ids
}
