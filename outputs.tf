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

output "aws_security_group" {
  description = "All of the `aws_security_group` resource outputs"
  value       = try(aws_security_group.default, null)
}

output "aws_security_group_rule" {
  description = "All of the `aws_security_group_rule` resource outputs"
  value       = try(aws_security_group_rule.default, null)
}
