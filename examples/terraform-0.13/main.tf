provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "v0.25.0"

  cidr_block = "10.0.0.0/24"

  assign_generated_ipv6_cidr_block = true

  context = module.this.context
}

# Create one new security group

module "new_security_group" {
  source = "../.."

  allow_all_egress = true

  rule_matrix = [{
    # Allow ingress on ports 22 and 80 from created security group, existing security group, and CIDR "10.0.0.0/8"

    # A derived value for source_security_group_ids breaks Terraform 0.13
    # source_security_group_ids = [aws_security_group.existing.id]
    source_security_group_ids = []
    # The dynamic value for CIDRs breaks Terraform 0.13
    cidr_blocks     = ["10.0.0.0/16"]
    prefix_list_ids = []
    self            = null
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
  }]

  rules = [
    {
      type                     = "ingress"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      cidr_blocks              = ["10.0.0.0/8"]
      ipv6_cidr_blocks         = [module.vpc.ipv6_cidr_block]
      source_security_group_id = null
      description              = "Discrete HTTPS ingress by CIDR"
      self                     = null
    },
    {
      type                     = "ingress"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      cidr_blocks              = []
      ipv6_cidr_blocks         = []
      source_security_group_id = aws_security_group.existing.id
      description              = "Discrete HTTPS ingress for special SG"
      self                     = null
    },
  ]


  vpc_id = module.vpc.vpc_id

  context = module.this.context
}


# Create rules for pre-created security group

resource "aws_security_group" "existing" {
  name_prefix = format("%s-%s-", module.this.id, "existing")
  vpc_id      = module.vpc.vpc_id
  tags        = module.this.tags
}
