variable "description" {
  type        = string
  default     = "Managed by Terraform"
  description = "The Security Group description."
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where Security Group will be created."

  validation {
    condition     = substr(var.vpc_id, 0, 4) == "vpc-" && length(var.vpc_id) > 4
    error_message = "The ami_id value must start with `ami-`."
  }
}

variable "security_group_enabled" {
  type        = bool
  default     = true
  description = "Whether to create Security Group."
}

variable "use_name_prefix" {
  type        = bool
  default     = false
  description = "Whether to create a unique name beginning with the normalized prefix."
}

variable "sg_id" {
  type        = string
  default     = null
  description = "The external Security Group ID to which Security Group rules will be assigned."
  validation {
    condition     = var.sg_id == null ? true : substr(var.sg_id, 0, 3) == "sg-" && length(var.sg_id) > 3
    error_message = "The sg_id value must start with `sg-`."
  }
}

variable "sg_rules" {
  type = list(object({
    type                     = string
    cidr_blocks              = list(string)
    ipv6_cidr_blocks         = list(string)
    prefix_list_ids          = list(string)
    from_port                = number
    to_port                  = number
    protocol                 = string
    security_group_id        = string
    source_security_group_id = string
    self                     = bool
    description              = string
  }))

  default     = []
  description = "Change me"
}
