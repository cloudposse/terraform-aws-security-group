variable "target_security_group_id" {
  type        = list(string)
  default     = []
  description = <<-EOT
    The ID of an existing Security Group to which Security Group rules will be assigned.
    The Security Group's description will not be changed.
    Not compatible with `inline_rules_enabled` or `revoke_rules_on_delete`.
    Required if `create_security_group` is `false`, ignored otherwise.
    EOT
  validation {
    condition     = length(var.target_security_group_id) < 2
    error_message = "Only 1 security group can be targeted."
  }
}

variable "security_group_name" {
  type        = list(string)
  default     = []
  description = <<-EOT
    The name to assign to the security group. Must be unique within the VPC.
    If not provided, will be derived from the `null-label.context` passed in.
    If `create_before_destroy` is true, will be used as a name prefix.
    EOT
  validation {
    condition     = length(var.security_group_name) < 2
    error_message = "Only 1 security group name can be provided."
  }
}


variable "security_group_description" {
  type        = string
  default     = "Managed by Terraform"
  description = <<-EOT
    The description to assign to the created Security Group.
    Warning: Changing the description causes the security group to be replaced.
    EOT
}

variable "create_before_destroy" {
  type        = bool
  default     = false
  description = <<-EOT
    Set `true` to enable terraform `create_before_destroy` behavior on the created security group.
    We recommend setting this `true` on new security groups, but default it to `false` because `true`
    will cause existing security groups to be replaced.
    Note that changing this value will always cause the security group to be replaced.
    EOT
}

variable "allow_all_egress" {
  type        = bool
  default     = false
  description = <<-EOT
    A convenience that adds to the rules specified elsewhere a rule that allows all egress.
    If this is false and no egress rules are specified via `rules` or `rule-matrix`, then no egress will be allowed.
    EOT
}

variable "rules" {
  type        = list(any)
  default     = []
  description = <<-EOT
    A list of Security Group rule objects. All elements of a list must be exactly the same type;
    use `rules_map` if you want to supply multiple lists of different types.
    The keys and values of the Security Group rule objects are fully compatible with the `aws_security_group_rule` resource,
    except for `security_group_id` which will be ignored, and the optional "key" which, if provided, must be unique
    and known at "plan" time.
    To get more info see the `security_group_rule` [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule).
    ___Note:___ The length of the list must be known at plan time.
    This means you cannot use functions like `compact` or `sort` when computing the list.
    EOT
}

variable "rules_map" {
  type        = any
  default     = {}
  description = <<-EOT
    A map-like object of lists of Security Group rule objects. All elements of a list must be exactly the same type,
    so this input accepts an object with keys (attributes) whose values are lists so you can separate different
    types into different lists and still pass them into one input. Keys must be known at "plan" time.
    The keys and values of the Security Group rule objects are fully compatible with the `aws_security_group_rule` resource,
    except for `security_group_id` which will be ignored, and the optional "key" which, if provided, must be unique
    and known at "plan" time.
    To get more info see the `security_group_rule` [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule).
    EOT
}

variable "rule_matrix" {
  # rule_matrix is independent of the `rules` input.
  # Only the rules specified in the `rule_matrix` object are applied to the subjects specified in `rule_matrix`.
  # The `key` attributes are optional, but if supplied, must be known at plan time or else
  # you will get an error from Terraform. If the value is triggering an error, just omit it.
  #  Schema:
  #  {
  #    # these top level lists define all the subjects to which rule_matrix rules will be applied
  #    key = unique key (for stability from plan to plan)
  #    source_security_group_ids = list of source security group IDs to apply all rules to
  #    cidr_blocks = list of ipv4 CIDR blocks to apply all rules to
  #    ipv6_cidr_blocks = list of ipv6 CIDR blocks to apply all rules to
  #    prefix_list_ids = list of prefix list IDs to apply all rules to
  #    self = # set "true" to apply the rules to the created or existing security group
  #
  #    # each rule in the rules list will be applied to every subject defined above
  #    rules = [{
  #      key = "unique key"
  #      type = "ingress"
  #      from_port = 433
  #      to_port = 433
  #      protocol = "tcp"
  #      description = "Allow HTTPS ingress"
  #    }]

  type        = any
  default     = []
  description = <<-EOT
    A convenient way to apply the same set of rules to a set of subjects. See README for details.
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

variable "revoke_rules_on_delete" {
  type        = bool
  default     = false
  description = <<-EOT
    Instruct Terraform to revoke all of the Security Group's attached ingress and egress rules before deleting
    the security group itself. This is normally not needed.
    EOT
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the Security Group will be created."
}

variable "inline_rules_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    NOT RECOMMENDED. Create rules "inline" instead of as separate `aws_security_group_rule` resources.
    See [#20046](https://github.com/hashicorp/terraform-provider-aws/issues/20046) for one of several issues with inline rules.
    See [this post](https://github.com/hashicorp/terraform-provider-aws/pull/9032#issuecomment-639545250) for details on the difference between inline rules and rule resources.
    EOT
}

