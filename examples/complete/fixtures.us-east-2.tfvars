region = "us-east-2"

namespace = "eg"

environment = "ue2"

stage = "test"

name = "sg"

rules = { default = [
  {
    key         = null # "ssh all"
    type        = "ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH wide open"
  },
  {
    key         = "https all"
    type        = "ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS wide open"
  }
  ],
  ipv6 = [
    {
      type             = "ingress"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = ["::/0"]
      description      = "SSH wide open"
    }

] }
