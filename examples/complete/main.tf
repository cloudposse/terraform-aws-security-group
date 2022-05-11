# Terraform for testing with terratest
#
# For this module, a large portion of the test is simply
# verifying that Terraform can generate a plan without errors.
#

provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "v1.1.0"

  cidr_block = "10.0.0.0/24"

  assign_generated_ipv6_cidr_block = true

  context = module.this.context
}

resource "random_integer" "coin" {
  max = 2
  min = 1
}

locals {
  coin = [random_integer.coin.result]
}

module "simple_security_group" {
  source = "../.."

  attributes = ["simple"]
  rules      = var.rules

  vpc_id = module.vpc.vpc_id

  context = module.this.context
}

# Create a new security group

module "new_security_group" {
  source = "../.."

  allow_all_egress     = true
  inline_rules_enabled = var.inline_rules_enabled

  rule_matrix = [{
    key = "stable"
    # Allow ingress on ports 22 and 80 from created security group, existing security group, and CIDR "10.0.0.0/8"
    # The dynamic value for source_security_group_ids breaks Terraform 0.13 but should work in 0.14 or later
    source_security_group_ids = [aws_security_group.target.id]
    # Either dynamic value for CIDRs breaks Terraform 0.13 but should work in 0.14 or later
    # In TF 0.14 and later (through 1.0.x) if the length of the cidr_blocks
    # list is not available at plan time, the module breaks.
    cidr_blocks      = random_integer.coin.result > 1 ? ["10.0.0.0/16"] : ["10.0.0.0/24"]
    ipv6_cidr_blocks = [module.vpc.vpc_ipv6_cidr_block]
    prefix_list_ids  = []

    # Making `self` derived should break `count`, as it legitimately makes
    # the count impossible to predict
    # self  =  random_integer.coin.result > 0
    self = var.rule_matrix_self
    rules = [
      {
        key         = "ssh"
        type        = "ingress"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        description = "Allow SSH access"
      },
      {
        # key = "http"
        type        = "ingress"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        description = "Allow HTTP access"
      },
    ]
  }]

  rules = var.rules
  rules_map = merge({ new-cidr = [
    {
      key                      = "https-cidr"
      type                     = "ingress"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      cidr_blocks              = ["10.0.0.0/8"]
      ipv6_cidr_blocks         = [module.vpc.vpc_ipv6_cidr_block] # ["::/0"] #
      source_security_group_id = null
      description              = "Discrete HTTPS ingress by CIDR"
      self                     = false
    }] }, {
    new-sg = [{
      # no key provided
      type                     = "ingress"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.target.id
      description              = "Discrete HTTPS ingress for special SG"
      self                     = null
    }],
  })


  vpc_id = module.vpc.vpc_id

  security_group_create_timeout = "5m"
  security_group_delete_timeout = "2m"

  security_group_name = [format("%s-%s", module.this.id, "new")]

  context = module.this.context
}


# Create rules for pre-created security group

resource "aws_security_group" "target" {
  name_prefix = format("%s-%s-", module.this.id, "existing")
  vpc_id      = module.vpc.vpc_id
  tags        = module.this.tags
}

module "target_security_group" {
  source = "../.."

  allow_all_egress = true
  # create_security_group    = false
  target_security_group_id = [aws_security_group.target.id]
  rules                    = var.rules

  security_group_name = [aws_security_group.target.name_prefix]
  vpc_id              = module.vpc.vpc_id

  context = module.this.context
}

# Disabled module

module "disabled_security_group" {
  source = "../.."

  vpc_id                   = module.vpc.vpc_id
  target_security_group_id = [aws_security_group.target.id]
  rules                    = var.rules

  context = module.this.context
  enabled = false
}
