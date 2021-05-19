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
    format("%v-%v-%v-%v-%s",
      rule.type,
      rule.protocol,
      rule.from_port,
      rule.to_port,
      try(rule["description"], null) == null ? md5(format("Managed by Terraform #%d", indx)) : md5(rule.description)
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

  security_group_id = local.id
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
