locals {
  security_group_enabled = module.this.enabled && var.security_group_enabled
  is_external            = module.this.enabled && var.security_group_enabled == false
  use_name               = var.use_name_prefix ? null : module.this.id
  use_name_prefix        = var.use_name_prefix ? format("%s%s", module.this.id, module.this.delimiter) : null
  id                     = local.is_external ? join("", data.aws_security_group.external.*.id) : join("", aws_security_group.default.*.id)
  arn                    = local.is_external ? join("", data.aws_security_group.external.*.arn) : join("", aws_security_group.default.*.arn)
  name                   = local.is_external ? join("", data.aws_security_group.external.*.name) : join("", aws_security_group.default.*.name)
  rules = module.this.enabled && var.rules != null ? {
    for indx, rule in flatten(var.rules) :
    format("%s-%s-%s-%s-%s",
      rule.type,
      rule.protocol,
      rule.from_port,
      rule.to_port,
      lookup(rule, "description", null) == null ? md5(format("Managed by Terraform #%d", indx)) : md5(rule.description)
      ) => {
      type        = rule.type
      protocol    = rule.protocol
      from_port   = rule.from_port
      to_port     = rule.to_port
      description = try(rule.description, format("Managed by Terraform #%d", indx))
    }
  } : {}
  source_security_group_id = module.this.enabled && var.rules != null ? {
    for indx, rule in flatten(var.rules) :
    format("%s-%s-%s-%s-%s",
      rule.type,
      rule.protocol,
      rule.from_port,
      rule.to_port,
      lookup(rule, "description", null) == null ? md5(format("Managed by Terraform #%d", indx)) : md5(rule.description)
    ) => try(rule.source_security_group_id, null)
  } : {}

  cidr_blocks = module.this.enabled && var.rules != null ? {
    for indx, rule in flatten(var.rules) :
    format("%s-%s-%s-%s-%s",
      rule.type,
      rule.protocol,
      rule.from_port,
      rule.to_port,
      lookup(rule, "description", null) == null ? md5(format("Managed by Terraform #%d", indx)) : md5(rule.description)
    ) => try(rule.cidr_blocks, null) != null ? (length(rule.cidr_blocks) > 0 ? rule.cidr_blocks : null) : null
  } : {}
  ipv6_cidr_blocks = module.this.enabled && var.rules != null ? {
    for indx, rule in flatten(var.rules) :
    format("%s-%s-%s-%s-%s",
      rule.type,
      rule.protocol,
      rule.from_port,
      rule.to_port,
      lookup(rule, "description", null) == null ? md5(format("Managed by Terraform #%d", indx)) : md5(rule.description)
    ) => try(rule.ipv6_cidr_blocks, null) != null ? (length(rule.ipv6_cidr_blocks) > 0 ? rule.ipv6_cidr_blocks : null) : null
  } : {}
  prefix_list_ids = module.this.enabled && var.rules != null ? {
    for indx, rule in flatten(var.rules) :
    format("%s-%s-%s-%s-%s",
      rule.type,
      rule.protocol,
      rule.from_port,
      rule.to_port,
      lookup(rule, "description", null) == null ? md5(format("Managed by Terraform #%d", indx)) : md5(rule.description)
    ) => try(rule.prefix_list_ids, null) != null ? (length(rule.prefix_list_ids) > 0 ? rule.prefix_list_ids : null) : null
  } : {}
  self = module.this.enabled && var.rules != null ? {
    for indx, rule in flatten(var.rules) :
    format("%s-%s-%s-%s-%s",
      rule.type,
      rule.protocol,
      rule.from_port,
      rule.to_port,
      lookup(rule, "description", null) == null ? md5(format("Managed by Terraform #%d", indx)) : md5(rule.description)
    ) => try(rule.self, null)
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
  description              = each.value.description
  cidr_blocks              = lookup(local.cidr_blocks, each.key, null)
  ipv6_cidr_blocks         = lookup(local.ipv6_cidr_blocks, each.key, null)
  prefix_list_ids          = lookup(local.prefix_list_ids, each.key, null)
  source_security_group_id = lookup(local.source_security_group_id, each.key, null)
  self                     = lookup(local.self, each.key, null)
}
