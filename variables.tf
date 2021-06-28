variable "vpc_id" {
  type        = string
  description = "The VPC ID where Security Group will be created."
}

variable "security_group_name" {
  type        = string
  default     = ""
  description = <<-EOT
    The name to assign to the security group. Must be unique within the account.
    If not provided, will be derived from the `null-label.context` passed in.
    If `create_before_destroy` is true, will be used as a name prefix.
  EOT
}

variable "create_security_group" {
  type        = bool
  default     = true
  description = "Set `true` to create a new security group. If false, `existing_security_group_id` must be provided."
}

variable "existing_security_group_id" {
  type        = string
  default     = ""
  description = <<-EOT
    The ID of an existing Security Group to which Security Group rules will be assigned.
    Required if `security_group_enabled` is `false`, ignored otherwise.
  EOT
}


variable "create_before_destroy" {
  type        = bool
  default     = false
  description = <<-EOT
    Set `true` to enable terraform `create_before_destroy` behavior.
    Note that changing this value will change the security group name.
    EOT
}

variable "description" {
  type        = string
  default     = "Managed by Terraform"
  description = "The Security Group description."
}

variable "rules" {
  type        = list(any)
  default     = []
  description = <<-EOT
    A list of maps of Security Group rules.
    The keys and values of the maps are fully compatible with the `aws_security_group_rule` resource, except
    for `security_group_id` which will be ignored.
    To get more info see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule .
  EOT
}

variable "allow_all_egress" {
  type        = bool
  default     = false
  description = <<-EOT
    A convenience that adds to the rules in `var.rules` a rule that allows all egress.
    If this is false and `var.rules` does not specify any egress rules, then
    no egress will be allowed.
    EOT
}

variable "rule_matrix" {
  # rule_matrix is independent of the `rules` input.
  # Only the rules specified in the `rule_matrix` object are applied to the subjects.
  #  Schema:
  #  {
  #    # these top level lists define all the subjects to which rule_matrix rules will be applied
  #    source_security_group_ids = list of source security group IDs to apply all rules to
  #    cidr_blocks = list of ipv4 CIDR blocks to apply all rules to
  #    ipv6_cidr_blocks= list of ipv6 CIDR blocks to apply all rules to
  #    prefix_list_ids = list of prefix list IDs to apply all rules to
  #    self = # set "true" to apply the rules to the created or existing security group
  #
  #    # each rule in the rules list will be applied to every subject defined above
  #    rules = [{
  #      type = "egress"
  #      from_port = 0
  #      to_port = 65535
  #      protocol = "all"
  #      description = "Allow full egress"
  #    }]

  type        = any
  default     = { rules = [] }
  description = <<-EOT
    A convenient way to apply the same set of rules to a set of subjects. See README for details.
    EOT
}

variable "unstable_output_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    Some outputs are unstable, meaning that they can show a change even when no resource changes are made.
    These outputs are suppressed by default. Set `unstable_output_enabled` to enable them.
    EOT
}
