locals {
  enabled = module.this.enabled
  # Because Terraform formatting for `not` (!) changes between versions 0.13 and 0.14, use == false instead
  create_security_group = local.enabled && var.create_security_group
  lookup_security_group = local.enabled && var.create_security_group == false
  created_security_group = local.create_security_group ? (
    var.create_before_destroy ? aws_security_group.cbd[0] : aws_security_group.default[0]
  ) : null
  security_group_id = local.enabled ? (
    # Use coalesce() here to hack an error message into the output
    var.create_security_group ? local.created_security_group.id : coalesce(var.existing_security_group_id,
    "`create_security_group` is false, but no ID was supplied ")
  ) : null

  rules = local.enabled && var.rules != null ? {
    for indx, rule in flatten(var.rules) :
    format("%v-%v-%v-%v-%s",
      rule.type,
      rule.protocol,
      rule.from_port,
      rule.to_port,
      try(rule["description"], null) == null ? md5(format("Managed by Terraform #%d", indx)) : md5(rule.description)
    ) => rule
  } : {}

  rule_matrix_rule_count = try(length(var.rule_matrix.rules), 0)
  rule_matrix_enabled    = local.enabled && local.rule_matrix_rule_count > 0
}

# You cannot toggle `create_before_destroy` based on input,
# you have to have a completely separate resource to change it.
resource "aws_security_group" "default" {
  # Because Terraform formatting for `not` (!) changes between versions 0.13 and 0.14, use == false instead
  count = local.create_security_group && var.create_before_destroy == false ? 1 : 0

  name        = coalesce(var.security_group_name, module.this.id)
  description = var.description
  vpc_id      = var.vpc_id
  tags        = merge(module.this.tags, length(var.security_group_name) > 0 ? { Name = var.security_group_name } : {})
}

resource "aws_security_group" "cbd" {
  # Because we use `== false` in the other resource, use `== true` for symmetry
  count = local.create_security_group && var.create_before_destroy == true ? 1 : 0

  name_prefix = coalesce(var.security_group_name, format("%s%s", module.this.id, module.this.delimiter))
  description = var.description
  vpc_id      = var.vpc_id
  tags        = merge(module.this.tags, length(var.security_group_name) > 0 ? { Name = var.security_group_name } : {})

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "default" {
  for_each = local.rules

  security_group_id = local.security_group_id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = lookup(each.value, "description", "Managed by Terraform")
  # Convert any of a missing key, a value of null, or a value of empty list to null
  cidr_blocks      = try(length(lookup(each.value, "cidr_blocks", [])), 0) > 0 ? each.value["cidr_blocks"] : null
  ipv6_cidr_blocks = try(length(lookup(each.value, "ipv6_cidr_blocks", [])), 0) > 0 ? each.value["ipv6_cidr_blocks"] : null
  prefix_list_ids  = try(length(lookup(each.value, "prefix_list_ids", [])), 0) > 0 ? each.value["prefix_list_ids"] : null
  self             = coalesce(lookup(each.value, "self", null), false) ? true : null

  source_security_group_id = lookup(each.value, "source_security_group_id", null)
}

resource "aws_security_group_rule" "self" {
  # We use "== true" here because you cannot use `null` as a conditional
  count = local.rule_matrix_enabled && try(var.rule_matrix.self, null) == true ? local.rule_matrix_rule_count : 0

  security_group_id = local.security_group_id
  type              = var.rule_matrix.rules[count.index].type
  from_port         = var.rule_matrix.rules[count.index].from_port
  to_port           = var.rule_matrix.rules[count.index].to_port
  protocol          = var.rule_matrix.rules[count.index].protocol
  description       = try(var.rule_matrix.rules[count.index].description, "Managed by Terraform")

  self = var.rule_matrix.self
}

resource "aws_security_group_rule" "sg" {
  # source_security_group_ids may be unknown at plan time and there is no valid proxy for them,
  # so there is no point in trying to come up with a static string key to use with for_each.
  count = local.rule_matrix_enabled ? length(var.rule_matrix.source_security_group_ids) * local.rule_matrix_rule_count : 0

  security_group_id = local.security_group_id
  type              = var.rule_matrix.rules[count.index % local.rule_matrix_rule_count].type
  from_port         = var.rule_matrix.rules[count.index % local.rule_matrix_rule_count].from_port
  to_port           = var.rule_matrix.rules[count.index % local.rule_matrix_rule_count].to_port
  protocol          = var.rule_matrix.rules[count.index % local.rule_matrix_rule_count].protocol
  description       = try(var.rule_matrix.rules[count.index % local.rule_matrix_rule_count].description, "Managed by Terraform")

  source_security_group_id = var.rule_matrix.source_security_group_ids[floor(count.index / local.rule_matrix_rule_count)]
}

resource "aws_security_group_rule" "cidr" {
  count = local.rule_matrix_enabled && (try(length(var.rule_matrix.cidr_blocks), 0) +
    try(length(var.rule_matrix.ipv6_cidr_blocks), 0) +
  try(length(var.rule_matrix.prefix_list_ids), 0)) > 0 ? local.rule_matrix_rule_count : 0

  security_group_id = local.security_group_id
  type              = "ingress"
  cidr_blocks       = try(length(var.rule_matrix.cidr_blocks), 0) > 0 ? var.rule_matrix.cidr_blocks : null
  ipv6_cidr_blocks  = try(length(var.rule_matrix.ipv6_cidr_blocks), 0) > 0 ? var.rule_matrix.ipv6_cidr_blocks : null
  prefix_list_ids   = try(length(var.rule_matrix.prefix_list_ids), 0) > 0 ? var.rule_matrix.prefix_list_ids : null
  from_port         = var.rule_matrix.rules[count.index].from_port
  to_port           = var.rule_matrix.rules[count.index].to_port
  protocol          = var.rule_matrix.rules[count.index].protocol
  description       = try(var.rule_matrix.rules[count.index].description, "Managed by Terraform")
}


resource "aws_security_group_rule" "egress" {
  count = local.enabled && var.allow_all_egress ? 1 : 0

  security_group_id = local.security_group_id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  description       = "Allow all egress"
}
