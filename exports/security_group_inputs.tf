# security_group_inputs Version: 1
#
# ONLY EDIT THIS FILE IN github.com/cloudposse/terraform-aws-security-group
# All other instances of this file should be a copy of that one
#
#
# Copy this file from https://github.com/cloudposse/terraform-aws-security-group/blob/master/exports/security_group_inputs.tf
#
# This file provides the standard inputs that all Cloud Posse Open Source
# Terraform module that create AWS Security Groups should implement.
# This file does NOT provide implementation of the inputs, as that
# of course varies with each module.
#
# This file documents, but does not declare, the standard outputs modules should create,
# again because the implementation will vary with modules.
#
# Unlike null-label context.tf, this file cannot be automatically updated
# because of the tight integration with the module using it.
#


variable "create_security_group" {
  type        = bool
  default     = true
  description = "Set `true` to create a new security group. If false, `target_security_group_id` must be provided."
}

variable "target_security_group_id" {
  type        = string
  default     = ""
  description = <<-EOT
    The ID of an existing Security Group to which Security Group rules will be assigned.
    Required if `create_security_group` is `false`, ignored otherwise.
  EOT
}

variable "security_group_name" {
  type        = string
  default     = ""
  description = <<-EOT
    The name to assign to the created security group. Must be unique within the account.
    If not provided, will be derived from the `null-label.context` passed in.
    If `create_before_destroy` is true, will be used as a name prefix.
  EOT
}

variable "security_group_description" {
  type        = string
  default     = "Managed by Terraform"
  description = <<-EOT
    The description to assign to the created Security Group.
    Warning: Changing the description causes the security group to be replaced, which requires everything
    associated with the security group to be replaced, which can be very disruptive.
    EOT
}

variable "security_group_create_before_destroy" {
  type        = bool
  default     = false
  description = <<-EOT
    Set `true` to enable terraform `create_before_destroy` behavior on the created security group.
    We recommend setting this `true` on new security groups, but default it to `false` because `true`
    will cause existing security groups to be replaced.
    Note that changing this value will also cause the security group to be replaced.
    EOT
}

variable "security_group_create_timeout" {
  type        = string
  default     = "10m"
  description = "How long to wait for the security group to be created."
}

variable "security_group_delete_timeout" {
  type        = string
  default     = "15m"
  description = <<-EOT
    How long to retry on `DependencyViolation` errors during security group deletion from
    lingering ENIs left by certain AWS services such as Elastic Load Balancing.
    EOT
}

#
#
#### The variables below can be omitted if not needed, and may need their descriptions modified
#
#
variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the Security Group will be created."
}

variable "revoke_security_group_rules_on_delete" {
  type        = bool
  default     = false
  description = <<-EOF
    Instruct Terraform to revoke all of the Security Group's attached ingress and egress rules before deleting
    the security group itself. This is normally not needed.
    EOF
}

variable "allow_all_egress" {
  type        = bool
  default     = true
  description = <<-EOT
    If `true`, the created security group will allow egress on all ports and protocols to all IP address.
    If this is false and no egress rules are otherwise specified, then no egress will be allowed.
    EOT
}

variable "associated_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IDs of Security Groups to associate the created resource with, in addition to the created or target security group.
  EOT
}

variable "allowed_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IDs of Security Groups to allow access to the created resource.
  EOT
}

##
##
################# Outputs
##
##
#
#  output "security_group_id" {
#    value = ""
#    description = "The ID of the created or target security group"
#  }
#
#  output "security_group_name" {
#    value = ""
#    description = "The name of the created or target security group"
#  }
