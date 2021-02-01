locals {
  security_group_enabled = module.this.enabled && var.security_group_enabled
  is_external            = module.this.enabled && var.security_group_enabled == false
  use_name               = var.use_name_prefix ? null : module.this.id
  use_name_prefix        = var.use_name_prefix ? format("%s%s", module.this.id, module.this.delimiter) : null
  id                     = local.is_external ? join("", data.aws_security_group.external.*.id) : join("", aws_security_group.default.*.id)
  arn                    = local.is_external ? join("", data.aws_security_group.external.*.arn) : join("", aws_security_group.default.*.arn)
  name                   = local.is_external ? join("", data.aws_security_group.external.*.name) : join("", aws_security_group.default.*.name)
  rules = module.this.enabled && var.rules != null ? {
    for rule in flatten(distinct(var.rules)) :
    format("%s-%s-%s-%s-%s-%s-%s-%s-%s-%s",
      rule.type,
      rule.protocol,
      rule.from_port,
      rule.to_port,
      lookup(rule, "cidr_blocks", null) == null ? "no_ipv4" : "ipv4",
      lookup(rule, "ipv6_cidr_blocks", null) == null ? "no_ipv6" : "ipv6",
      lookup(rule, "security_group_id", null) == null ? "no_ssg" : "ssg",
      lookup(rule, "prefix_list_ids", null) == null ? "no_pli" : "pli",
      lookup(rule, "self", null) == null ? "no_self" : "self",
      lookup(rule, "description", null) == null ? "no_desc" : "desc"
    ) => rule
  } : {}
}

data "aws_security_group" "external" {
  count  = local.is_external ? 1 : 0
  id     = var.id
  vpc_id = var.vpc_id
}

resource "aws_security_group" "default" {
  count = local.security_group_enabled && local.is_external == false ? 1 : 0

  name        = local.use_name
  name_prefix = local.use_name_prefix
  description = var.description
  vpc_id      = var.vpc_id
  tags        = module.this.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "default" {
  for_each = local.rules

  security_group_id        = local.id
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  self                     = lookup(each.value, "self", null) == null ? false : each.value.self
  description              = lookup(each.value, "description", null) == null ? "Managed by Terraform" : each.value.description
}
