# security_group_inputs Version: 1
#
# Copy this file from https://github.com/cloudposse/terraform-aws-security-group/blob/master/exports/security_group_inputs.tf
# and EDIT IT TO SUIT YOUR PROJECT. Update the version number above if you update this file from a later version.
#
# KEEP this top comment block, but REMOVE COMMENTS below that are intended
# for the initial implementor and not maintainers or end users.
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
  description = "Set `true` to create and configure a new security group. If false, `associated_security_group_ids` must be provided."
}

variable "associated_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IDs of Security Groups to associate the created resource with, in addition to the created security group.
    These security groups will not be modified and, if `create_security_group` is `false`, must provide all the required access.
  EOT
}

variable "allowed_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IDs of Security Groups to allow access to the security group created by this module.
  EOT
}

variable "security_group_name" {
  type        = list(string)
  default     = []
  description = <<-EOT
    The name to assign to the created security group. Must be unique within the VPC.
    If not provided, will be derived from the `null-label.context` passed in.
    If `create_before_destroy` is true, will be used as a name prefix.
  EOT
}

variable "security_group_description" {
  type        = string
  default     = "Managed by Terraform"
  description = <<-EOT
    The description to assign to the created Security Group.
    Warning: Changing the description causes the security group to be replaced.
    EOT
}

###############################
#
# Decide on a case-by-case basis what the default should be.
# In general, if the resource supports changing security groups without deleting
# the resource or anything it depends on, then default it to `true` and
# note in the release notes and migration documents the option to
# set it to `false` to preserve the existing security group.
# If the resource has to be deleted to change its security group,
# then set the default to `false` and highlight the option to change
# it to `true` in the release notes and migration documents.
#
################################
variable "security_group_create_before_destroy" {
  type = bool
  #
  # Pick `true` or `false` and the associated description
  # Replace "the resource" with the name of the resouce, e.g. "EC2 instance"
  #

  #  default     = false
  #  description = <<-EOT
  #    Set `true` to enable Terraform `create_before_destroy` behavior on the created security group.
  #    We recommend setting this `true` on new security groups, but default it to `false` because `true`
  #    will cause existing security groups to be replaced, possibly requiring the resource to be deleted and recreated.
  #    Note that changing this value will always cause the security group to be replaced.
  #    EOT

  #  default     = true
  #  description = <<-EOT
  #    Set `true` to enable Terraform `create_before_destroy` behavior on the created security group.
  #    We only recommend setting this `false` if you are upgrading this module and need to keep
  #    the existing security group from being replaced.
  #    Note that changing this value will always cause the security group to be replaced.
  #    EOT
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

#############################################################################################
## Special note about inline_rules_enabled and revoke_rules_on_delete
##
## The security-group inputs inline_rules_enabled and revoke_rules_on_delete should not
## be exposed in other modules unless there is a strong reason for them to be used.
## We discourage the use of inline_rules_enabled and we rarely need or want
## revoke_rules_on_delete, so we do not want to clutter our interface with those inputs.
##
## If someone wants to enable either of those options, they have the option
## of creating a security group configured as they like
## and passing it in as the target security group.
#############################################################################################

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
    If `true`, the created security group will allow egress on all ports and protocols to all IP addresses.
    If this is false and no egress rules are otherwise specified, then no egress will be allowed.
    EOT
}

variable "additional_security_group_rules" {
  type        = list(any)
  default     = []
  description = <<-EOT
    A list of Security Group rule objects to add to the created security group, in addition to the ones
    this module normally creates. (To suppress the module's rules, set `create_security_group` to false
    and supply your own security group(s) via `associated_security_group_ids`.)
    The keys and values of the objects are fully compatible with the `aws_security_group_rule` resource, except
    for `security_group_id` which will be ignored, and the optional "key" which, if provided, must be unique and known at "plan" time.
    For more info see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
    and https://github.com/cloudposse/terraform-aws-security-group.
    EOT
}

#
#
#### The variable `additional_security_group_rule_matrix` should normally be omitted, for a few reasons:
# - It is a convenience and ultimately provides no rules that cannot be provided via `additional_security_group_rules`
# - It is complicated and can, in some situations, create problems for Terraform `for_each`
# - It is difficult to document and easy to make mistakes using it
#
#


##
##
################# Outputs
##
##
#
#  output "security_group_id" {
#    value = ""
#    description = "The ID of the created security group"
#  }
#
#  output "security_group_name" {
#    value = ""
#    description = "The name of the created security group"
#  }

