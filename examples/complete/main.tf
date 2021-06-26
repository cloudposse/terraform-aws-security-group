provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "v0.25.0"

  cidr_block = "10.0.0.0/24"

  context = module.this.context
}

# Create new one security group

module "new_security_group" {
  source = "../.."

  vpc_id              = module.vpc.vpc_id
  open_egress_enabled = true
  rule_matrix = {
    # Allow ingress on ports 22 and 80 from created security grup, existing security group, and CIDR "10.0.0.0/8"
    source_security_group_ids = [aws_security_group.existing.id]
    cidr_blocks               = ["10.0.0.0/8"]
    prefix_list_ids           = null
    self                      = true
    rules = [
      {
        type        = "ingress"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        description = "Allow SSH access"
      },
      {
        type        = "ingress"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        description = "Allow HTTP access"
      },
    ]
  }
  rules = [
    {
      type                     = "ingress"
      from_port                = 443
      to_port                  = 443
      protocol                 = "all"
      cidr_blocks              = ["0.0.0.0/0"]
      ipv6_cidr_blocks         = null
      source_security_group_id = null
      description              = null
      self                     = null
    },
  ]

  context = module.this.context
}

# Create rules for pre-created security group

resource "aws_security_group" "existing" {
  name_prefix = format("%s-%s-", module.this.id, "existing")
  vpc_id      = module.vpc.vpc_id
  tags        = module.this.tags
}

module "existing_security_group" {
  source = "../.."

  vpc_id                     = module.vpc.vpc_id
  existing_security_group_id = aws_security_group.existing.id
  rules                      = var.rules
  create_security_group      = false

  context = module.this.context
}

# Disabled module

module "disabled_security_group" {
  source = "../.."

  vpc_id                     = module.vpc.vpc_id
  existing_security_group_id = aws_security_group.existing.id
  rules                      = var.rules

  context = module.this.context
  enabled = false
}
