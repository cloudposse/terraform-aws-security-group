# In this file, we normalize all the rules into full objects with all keys.
# Then we partition the normalized rules for use as either inline or resourced rules.

locals {

  # We have var.rules_map as a key-value object where the values are lists of different types.
  # For convenience, the ordinary use cases, and ease of understanding, we also have var.rules,
  # which is a single list of rules. First thing we do is to combine the 2 into one object.
  rules = merge({ _list_ = var.rules }, var.rules_map)

  # Note: we have to use [] instead of null for unset lists due to
  # https://github.com/hashicorp/terraform/issues/28137
  # which was not fixed until Terraform 1.0.0
  norm_rules = local.enabled && local.rules != null ? concat(concat([[]], [for k, rules in local.rules : [for i, rule in rules : {
    key         = coalesce(lookup(rule, "key", null), "${k}[${i}]")
    type        = rule.type
    from_port   = rule.from_port
    to_port     = rule.to_port
    protocol    = rule.protocol
    description = lookup(rule, "description", local.default_rule_description)

    # Convert a missing key, a value of null, or a value of empty list to []
    cidr_blocks      = try(length(rule.cidr_blocks), 0) > 0 ? rule.cidr_blocks : []
    ipv6_cidr_blocks = try(length(rule.ipv6_cidr_blocks), 0) > 0 ? rule.ipv6_cidr_blocks : []
    prefix_list_ids  = try(length(rule.prefix_list_ids), 0) > 0 ? rule.prefix_list_ids : []

    source_security_group_id = lookup(rule, "source_security_group_id", null)
    security_groups          = []

    # self conflicts with other arguments, so it must either be
    # null or true (in which case we split it out into a separate rule)
    self = lookup(rule, "self", null) == true ? true : null
  }]])...) : []

  # in rule_matrix and inline rules, a single rule can have a list of security groups
  norm_matrix = local.enabled && var.rule_matrix != null ? concat(concat([[]], [for i, subject in var.rule_matrix : [for j, rule in subject.rules : {
    key         = "${coalesce(lookup(subject, "key", null), "_m[${i}]")}#${coalesce(lookup(rule, "key", null), "[${j}]")}"
    type        = rule.type
    from_port   = rule.from_port
    to_port     = rule.to_port
    protocol    = rule.protocol
    description = lookup(rule, "description", local.default_rule_description)

    # We tried to be lenient and convert a missing key, a value of null, or a value of empty list to []
    # with cidr_blocks = try(length(rule.cidr_blocks), 0) > 0 ? rule.cidr_blocks : []
    # but if a list is provided and any value in the list is not available at plan time,
    # that formulation causes problems for `count`, so we must forbid keys present with value of null.

    cidr_blocks      = lookup(subject, "cidr_blocks", [])
    ipv6_cidr_blocks = lookup(subject, "ipv6_cidr_blocks", [])
    prefix_list_ids  = lookup(subject, "prefix_list_ids", [])

    source_security_group_id = null
    security_groups          = lookup(subject, "source_security_group_ids", [])

    # self conflicts with other arguments, so it must either be
    # null or true (in which case we split it out into a separate rule)
    self = lookup(rule, "self", null) == true ? true : null
  }]])...) : []

  allow_egress_rule = {
    key                      = "_allow_all_egress_"
    type                     = "egress"
    from_port                = 0
    to_port                  = 0 # [sic] from and to port ignored when protocol is "-1", warning if not zero
    protocol                 = "-1"
    description              = "Allow all egress"
    cidr_blocks              = ["0.0.0.0/0"]
    ipv6_cidr_blocks         = ["::/0"]
    prefix_list_ids          = []
    self                     = null
    security_groups          = []
    source_security_group_id = null
  }

  extra_rules = local.allow_all_egress ? [local.allow_egress_rule] : []

  all_inline_rules = concat(local.norm_rules, local.norm_matrix, local.extra_rules)

  # For inline rules, the rules have to be separated into ingress and egress
  all_ingress_rules = local.inline ? [for r in local.all_inline_rules : r if r.type == "ingress"] : []
  all_egress_rules  = local.inline ? [for r in local.all_inline_rules : r if r.type == "egress"] : []

  # In `aws_security_group_rule` a rule can only have one security group, not a list, so we have to explode the matrix
  # Also, self, source_security_group_id, and CIDRs conflict with each other, so they have to be separated out.
  # We must be very careful not to make the computed number of rules in any way dependant
  # on a computed input value, we must stick to counting things.

  self_rules = local.inline ? [] : [for rule in local.norm_matrix : {
    key         = "${rule.key}#self"
    type        = rule.type
    from_port   = rule.from_port
    to_port     = rule.to_port
    protocol    = rule.protocol
    description = rule.description

    cidr_blocks      = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = true

    security_groups          = []
    source_security_group_id = null

    # To preserve count and order of rules, we would like to create rules for `false`
    # even though they do nothing, but an empty rule is not allowed, so we have to
    # create the rule only when `self` is `true`.
    # We use `== true` because `self` could be `null` and `if null` is not allowed.
  } if rule.self == true]

  other_rules = local.inline ? [] : [for rule in local.norm_matrix : {
    key         = "${rule.key}#cidr"
    type        = rule.type
    from_port   = rule.from_port
    to_port     = rule.to_port
    protocol    = rule.protocol
    description = rule.description

    cidr_blocks      = rule.cidr_blocks
    ipv6_cidr_blocks = rule.ipv6_cidr_blocks
    prefix_list_ids  = rule.prefix_list_ids
    self             = null

    security_groups          = []
    source_security_group_id = null
  } if length(rule.cidr_blocks) + length(rule.ipv6_cidr_blocks) + length(rule.prefix_list_ids) > 0]


  # First, collect all the rules with lists of security groups
  sg_rules_lists = local.inline ? [] : [for rule in local.all_inline_rules : {
    key         = "${rule.key}#sg"
    type        = rule.type
    from_port   = rule.from_port
    to_port     = rule.to_port
    protocol    = rule.protocol
    description = rule.description

    cidr_blocks      = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = null
    security_groups  = rule.security_groups
  } if length(rule.security_groups) > 0]

  # Now we have to explode the lists into individual rules
  sg_exploded_rules = flatten([for rule in local.sg_rules_lists : [for i, sg in rule.security_groups : {
    key         = "${rule.key}#${i}"
    type        = rule.type
    from_port   = rule.from_port
    to_port     = rule.to_port
    protocol    = rule.protocol
    description = rule.description

    cidr_blocks      = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = null

    security_groups          = []
    source_security_group_id = sg
  }]])

  all_resource_rules   = concat(local.norm_rules, local.self_rules, local.sg_exploded_rules, local.other_rules, local.extra_rules)
  keyed_resource_rules = { for r in local.all_resource_rules : r.key => r }
}
