locals {
  security_group_enabled = module.this.enabled && var.security_group_enabled
  is_external            = module.this.enabled && var.security_group_enabled == false
  use_name               = var.use_name_prefix ? null : module.this.id
  use_name_prefix        = var.use_name_prefix ? format("%s%s", module.this.id, module.this.delimiter) : null
  id                     = local.is_external ? join("", data.aws_security_group.external.*.id) : join("", aws_security_group.default.*.id)
  arn                    = local.is_external ? join("", data.aws_security_group.external.*.arn) : join("", aws_security_group.default.*.arn)
  name                   = local.is_external ? join("", data.aws_security_group.external.*.name) : join("", aws_security_group.default.*.name)
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
  count = module.this.enabled ? length(flatten(var.rules)) : 0

  security_group_id        = local.id
  type                     = var.rules[count.index].type
  from_port                = var.rules[count.index].from_port
  to_port                  = var.rules[count.index].to_port
  protocol                 = var.rules[count.index].protocol
  cidr_blocks              = var.rules[count.index].cidr_blocks != null && length(var.rules[count.index].cidr_blocks) > 0 ? var.rules[count.index].cidr_blocks : null
  ipv6_cidr_blocks         = var.rules[count.index].ipv6_cidr_blocks != null && length(var.rules[count.index].ipv6_cidr_blocks) > 0 ? var.rules[count.index].ipv6_cidr_blocks : null
  prefix_list_ids          = var.rules[count.index].prefix_list_ids != null && length(var.rules[count.index].prefix_list_ids) > 0 ? var.rules[count.index].prefix_list_ids : null
  source_security_group_id = try(var.rules[count.index].source_security_group_id, null)
  self                     = try(var.rules[count.index].self, null)
  description              = try(var.rules[count.index].description, "Managed by Terraform")
}
