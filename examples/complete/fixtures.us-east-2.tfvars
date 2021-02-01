region = "us-east-2"

namespace = "eg"

environment = "ue2"

stage = "test"

name = "sg"

rules = [
  {
    type        = "ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    type        = "egress"
    from_port   = 0
    to_port     = 65535
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
]
