locals {
  security_group_enabled = module.this.enabled && var.security_group_enabled ? 1 : 0
  name                   = var.use_name_prefix ? null : module.this.id
  name_prefix            = var.use_name_prefix ? format("%s%s", module.this.id, module.delimiter) : null
  sg_id                  = local.security_group_enabled ? try(aws_security_group.default.id, "") : var.sg_id
  sg_rules               = module.this.enabled ? var.sg_rules : []

}

resource "aws_security_group" "default" {
  count = local.security_group_enabled

  name        = local.name
  name_prefix = local.name_prefix
  description = var.description
  vpc_id      = var.vpc_id
  tags        = module.this.tags
}

resource "aws_security_group_rule" "default" {
  for_each = local.sg_rules

  type                     = each.value.type      # Required
  from_port                = each.value.from_port # Required
  to_port                  = each.value.to_port   # Required
  protocol                 = each.value.protocol  # Required
  cidr_blocks              = try(each.value.cidr_blocks, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr_blocks, null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
  security_group_id        = local.sg_id
  source_security_group_id = try(each.value.source_security_group_id, null)
  self                     = try(each.value.self, null)
  description              = try(each.value.self, "Managed by Terraform")
}
