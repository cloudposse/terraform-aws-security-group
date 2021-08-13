variable "region" {
  type = string
}

variable "rules" {
  type        = any
  description = "List of security group rules to apply to the created security group"
}

variable "rule_matrix_self" {
  type        = bool
  description = "Value to set `self` in `rule_matrix` test rule"
  default     = null
}

variable "inline_rules_enabled" {
  type        = bool
  description = "Flag to enable/disable inline security group rules"
  default     = false
}
