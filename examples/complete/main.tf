provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "v0.18.2"

  cidr_block = "10.0.0.0/16"

  context = module.this.context
}

# Create new one security group

module "new_security_group" {
  source = "../.."

  vpc_id = module.vpc.vpc_id
  rules = [
    {
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.dynamic.id
      cidr_blocks              = []
    },
    {
      type                     = "egress"
      from_port                = 0
      to_port                  = 65535
      protocol                 = "all"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
    }
  ]

  context = module.this.context
}

# Create rules for pre-created security group

resource "aws_security_group" "external" {
  name_prefix = format("%s-%s-", module.this.id, "external")
  vpc_id      = module.vpc.vpc_id
  tags        = module.this.tags
}

resource "aws_security_group" "dynamic" {
  name_prefix = format("%s-%s-", module.this.id, "dynamic")
  vpc_id      = module.vpc.vpc_id
  tags        = module.this.tags
}

module "external_security_group" {
  source = "../.."

  vpc_id                 = module.vpc.vpc_id
  id                     = aws_security_group.external.id
  rules                  = var.rules
  security_group_enabled = false

  context = module.this.context
}

# Disabled module

module "disabled_security_group" {
  source = "../.."

  vpc_id  = module.vpc.vpc_id
  id      = aws_security_group.external.id
  rules   = var.rules
  context = module.this.context
  enabled = false
}
