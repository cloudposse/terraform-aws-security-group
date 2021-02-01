variable "vpc_id" {
  type        = string
  description = "The VPC ID where Security Group will be created."
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

variable "description" {
  type        = string
  default     = "Managed by Terraform"
  description = "The Security Group description."
}

variable "id" {
  type        = string
  default     = ""
  description = <<-EOT
    The external Security Group ID to which Security Group rules will be assigned.
    Required to set `security_group_enabled` to `false`.
  EOT
}

variable "rules" {
  type        = list(any)
  default     = null
  description = <<-EOT
    A list of maps of Security Group rules. 
    The values of map is fully complated with `aws_security_group_rule` resource. 
    To get more info see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule .
  EOT
}
