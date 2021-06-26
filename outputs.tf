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

output "security_group_details" {
  description = "Details about the security group created"
  value       = var.create_before_destroy ? aws_security_group.cbd : aws_security_group.default
}

output "rules" {
  description = "Details about all the security group rules created"
  value       = concat(try(values(aws_security_group_rule.default), []), aws_security_group_rule.sg, aws_security_group_rule.cidr, aws_security_group_rule.self, aws_security_group_rule.egress)
}
