locals {
  enabled = module.this.enabled
  default_rule_description = "Managed by Terraform"
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

  rules = local.enabled && var.rules != null ? var.rules : []

  rule_matrix_rule_count = try(length(var.rule_matrix.rules), 0)
  rule_matrix_enabled    = local.enabled && local.rule_matrix_rule_count > 0
}

# You cannot toggle `create_before_destroy` based on input,
# you have to have a completely separate resource to change it.
resource "aws_security_group" "default" {
  # Because Terraform formatting for `not` (!) changes between versions 0.13 and 0.14, use == false instead
  count = local.create_security_group && var.create_before_destroy == false ? 1 : 0

  name        = coalesce(var.security_group_name, module.this.id)
  description = var.security_group_description
  vpc_id      = var.vpc_id
  tags        = merge(module.this.tags, length(var.security_group_name) > 0 ? { Name = var.security_group_name } : {})
}

resource "aws_security_group" "cbd" {
  # Because we use `== false` in the other resource, use `== true` for symmetry
  count = local.create_security_group && var.create_before_destroy == true ? 1 : 0

  name_prefix = coalesce(var.security_group_name, format("%s%s", module.this.id, module.this.delimiter))
  description = var.security_group_description
  vpc_id      = var.vpc_id
  tags        = merge(module.this.tags, length(var.security_group_name) > 0 ? { Name = var.security_group_name } : {})

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "default" {
  count = length(local.rules)

  security_group_id = local.security_group_id
  type              = local.rules[count.index].type
  from_port         = local.rules[count.index].from_port
  to_port           = local.rules[count.index].to_port
  protocol          = local.rules[count.index].protocol
  description       = lookup(local.rules[count.index], "description", local.default_rule_description)
  # Convert a missing key, a value of null, or a value of empty list to null
  cidr_blocks      = try(length(lookup(local.rules[count.index], "cidr_blocks", [])), 0) > 0 ? local.rules[count.index]["cidr_blocks"] : null
  ipv6_cidr_blocks = try(length(lookup(local.rules[count.index], "ipv6_cidr_blocks", [])), 0) > 0 ? local.rules[count.index]["ipv6_cidr_blocks"] : null
  prefix_list_ids  = try(length(lookup(local.rules[count.index], "prefix_list_ids", [])), 0) > 0 ? local.rules[count.index]["prefix_list_ids"] : null
  self             = coalesce(lookup(local.rules[count.index], "self", null), false) ? true : null

  source_security_group_id = lookup(local.rules[count.index], "source_security_group_id", null)
}

resource "aws_security_group_rule" "self" {
  # We use "== true" here because you cannot use `null` as a conditional, but null == true is OK
  count = local.rule_matrix_enabled && try(var.rule_matrix.self, null) == true ? local.rule_matrix_rule_count : 0

  security_group_id = local.security_group_id
  type              = var.rule_matrix.rules[count.index].type
  from_port         = var.rule_matrix.rules[count.index].from_port
  to_port           = var.rule_matrix.rules[count.index].to_port
  protocol          = var.rule_matrix.rules[count.index].protocol
  description       = try(var.rule_matrix.rules[count.index].description, local.default_rule_description)

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
  description       = try(var.rule_matrix.rules[count.index % local.rule_matrix_rule_count].description, local.default_rule_description)

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
  description       = try(var.rule_matrix.rules[count.index].description, local.default_rule_description)
}


resource "aws_security_group_rule" "egress" {
  count = local.enabled && var.allow_all_egress ? 1 : 0

  security_group_id = local.security_group_id

  # Copied from https://registry.terraform.io/providers/hashicorp/aws/3.46.0/docs/resources/security_group#example-usage
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  description       = "Allow all egress"
}
