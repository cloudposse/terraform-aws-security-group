locals {
  enabled = module.this.enabled
  inline  = var.inline_rules_enabled

  allow_all_egress = local.enabled && var.allow_all_egress

  default_rule_description = "Managed by Terraform"

  # Because Terraform formatting for `not` (!) changes between versions 0.13 and 0.14, use == false instead
  create_security_group = local.enabled && var.create_security_group

  created_security_group = local.create_security_group ? (
    var.create_before_destroy ? aws_security_group.cbd[0] : aws_security_group.default[0]
  ) : null

  security_group_id = local.enabled ? (
    # Use coalesce() here to hack an error message into the output
    var.create_security_group ? local.created_security_group.id : coalesce(var.target_security_group_id,
    "`create_security_group` is false, but no ID was supplied ")
  ) : null
}

# You cannot toggle `create_before_destroy` based on input,
# you have to have a completely separate resource to change it.
resource "aws_security_group" "default" {
  # Because Terraform formatting for `not` (!) changes between versions 0.13 and 0.14, use == false instead
  count = local.create_security_group && var.create_before_destroy == false ? 1 : 0

  name = coalesce(var.security_group_name, module.this.id)

  ########################################################################
  ## Everything from here to the end of this resource should be identical
  ## (copy and paste) in aws_security_group.default and aws_security_group.cbd

  description = var.security_group_description
  vpc_id      = var.vpc_id
  tags        = try(length(var.security_group_name), 0) > 0 ? merge(module.this.tags, { Name = var.security_group_name }) : module.this.tags

  revoke_rules_on_delete = var.revoke_rules_on_delete

  dynamic "ingress" {
    for_each = local.all_ingress_rules
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      description      = ingress.value.description
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      prefix_list_ids  = ingress.value.prefix_list_ids
      security_groups  = ingress.value.security_groups
      self             = ingress.value.self
    }
  }

  dynamic "egress" {
    for_each = local.all_egress_rules
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      description      = egress.value.description
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      prefix_list_ids  = egress.value.prefix_list_ids
      security_groups  = egress.value.security_groups
      self             = egress.value.self
    }
  }

  timeouts {
    create = var.security_group_create_timeout
    delete = var.security_group_delete_timeout
  }

  ##
  ## end of duplicate block
  ########################################################################

}

resource "aws_security_group" "cbd" {
  # Because we use `== false` in the other resource, use `== true` for symmetry
  count = local.create_security_group && var.create_before_destroy == true ? 1 : 0

  name_prefix = coalesce(var.security_group_name, "${module.this.id}${module.this.delimiter}")
  lifecycle {
    create_before_destroy = true
  }

  ########################################################################
  ## Everything from here to the end of this resource should be identical
  ## (copy and paste) in aws_security_group.default and aws_security_group.cbd

  description = var.security_group_description
  vpc_id      = var.vpc_id
  tags        = try(length(var.security_group_name), 0) > 0 ? merge(module.this.tags, { Name = var.security_group_name }) : module.this.tags

  revoke_rules_on_delete = var.revoke_rules_on_delete

  dynamic "ingress" {
    for_each = local.all_ingress_rules
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      description      = ingress.value.description
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      prefix_list_ids  = ingress.value.prefix_list_ids
      security_groups  = ingress.value.security_groups
      self             = ingress.value.self
    }
  }

  dynamic "egress" {
    for_each = local.all_egress_rules
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      description      = egress.value.description
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      prefix_list_ids  = egress.value.prefix_list_ids
      security_groups  = egress.value.security_groups
      self             = egress.value.self
    }
  }

  timeouts {
    create = var.security_group_create_timeout
    delete = var.security_group_delete_timeout
  }

  ##
  ## end of duplicate block
  ########################################################################

}

resource "aws_security_group_rule" "discrete" {
  # We cannot use for_each here because some of the values in resource_rules may not be available at plan time
  count = length(local.resource_rules)

  type             = local.resource_rules[count.index].type
  from_port        = local.resource_rules[count.index].from_port
  to_port          = local.resource_rules[count.index].to_port
  protocol         = local.resource_rules[count.index].protocol
  description      = local.resource_rules[count.index].description
  cidr_blocks      = length(local.resource_rules[count.index].cidr_blocks) == 0 ? null : local.resource_rules[count.index].cidr_blocks
  ipv6_cidr_blocks = length(local.resource_rules[count.index].ipv6_cidr_blocks) == 0 ? null : local.resource_rules[count.index].ipv6_cidr_blocks
  prefix_list_ids  = length(local.resource_rules[count.index].prefix_list_ids) == 0 ? null : local.resource_rules[count.index].prefix_list_ids
  self             = local.resource_rules[count.index].self

  security_group_id        = local.security_group_id
  source_security_group_id = local.resource_rules[count.index].source_security_group_id

  depends_on = [aws_security_group.cbd, aws_security_group.default]
}

