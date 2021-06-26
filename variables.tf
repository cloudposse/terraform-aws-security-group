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

variable "open_egress_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    A convenience. Add to the rules in `var.rules` a rule that allows all egress.
    If this is false and `var.rules` does not specify any egress rules, then
    no egress will be allowed.
    EOT
}

variable "rule_matrix" {
  type        = any
  default     = { rules = [] }
  description = <<-EOT
    A convenience. Apply the same list of rules to all the provided security groups and CIDRs and self.
    Type is object as specified in the default, but keys are optional except for `rules`.
    The `rules` list is a list of maps that are fully compatible with the `aws_security_group_rule` resource,
    but any keys already at the top level will be ignored.  Rules keys listed in the default are required, except for `description`.
    All elements of the list must have the same set of keys and each key must have a consistent value type.
    Example:
    {
      source_security_group_ids = []
      cidr_blocks= []
      ipv6_cidr_blocks= []
      prefix_list_ids = []
      self = true
      rules = [{
        type = "egress"
        from_port = 0
        to_port = 65535
        protocol = "all"
        description = "Allow full egress"
    }]
    EOT
}
