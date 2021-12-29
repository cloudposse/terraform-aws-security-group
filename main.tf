locals {
  enabled = module.this.enabled
  inline  = var.inline_rules_enabled

  allow_all_egress = local.enabled && var.allow_all_egress

  default_rule_description = "Managed by Terraform"

  create_security_group = local.enabled && length(var.target_security_group_id) == 0

  created_security_group = local.create_security_group ? (
    var.create_before_destroy ? aws_security_group.cbd[0] : aws_security_group.default[0]
  ) : null

  security_group_id = local.enabled ? (
    # Use coalesce() here to hack an error message into the output
    local.create_security_group ? local.created_security_group.id : coalesce(var.target_security_group_id[0],
    "var.target_security_group_id contains null value. Omit value if you want this module to create a security group.")
  ) : null
}

# You cannot toggle `create_before_destroy` based on input,
# you have to have a completely separate resource to change it.
resource "aws_security_group" "default" {
  # Because we have 2 almost identical alternatives, use x == false and x == true rather than x and !x
  count = local.create_security_group && var.create_before_destroy == false ? 1 : 0

  name = concat(var.security_group_name, [module.this.id])[0]

  ########################################################################
  ## Everything from here to the end of this resource should be identical
  ## (copy and paste) in aws_security_group.default and aws_security_group.cbd

  description = var.security_group_description
  vpc_id      = var.vpc_id
  tags        = merge(module.this.tags, try(length(var.security_group_name[0]), 0) > 0 ? { Name = var.security_group_name[0] } : {})

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
  # Because we have 2 almost identical alternatives, use x == false and x == true rather than x and !x
  count = local.create_security_group && var.create_before_destroy == true ? 1 : 0

  name_prefix = concat(var.security_group_name, ["${module.this.id}${module.this.delimiter}"])[0]
  lifecycle {
    create_before_destroy = true
  }

  ########################################################################
  ## Everything from here to the end of this resource should be identical
  ## (copy and paste) in aws_security_group.default and aws_security_group.cbd

  description = var.security_group_description
  vpc_id      = var.vpc_id
  tags        = merge(module.this.tags, try(length(var.security_group_name[0]), 0) > 0 ? { Name = var.security_group_name[0] } : {})

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

resource "aws_security_group_rule" "keyed" {
  for_each = local.keyed_resource_rules

  security_group_id = local.security_group_id

  type        = each.value.type
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = each.value.description

  cidr_blocks              = length(each.value.cidr_blocks) == 0 ? null : each.value.cidr_blocks
  ipv6_cidr_blocks         = length(each.value.ipv6_cidr_blocks) == 0 ? null : each.value.ipv6_cidr_blocks
  prefix_list_ids          = length(each.value.prefix_list_ids) == 0 ? [] : each.value.prefix_list_ids
  self                     = each.value.self
  source_security_group_id = each.value.source_security_group_id

  depends_on = [aws_security_group.cbd, aws_security_group.default]

  lifecycle {
    create_before_destroy = true
  }
}
