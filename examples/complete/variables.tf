variable "region" {
  type = string
}

variable "rules" {
  type = any
}

variable "rule_matrix_self" {
  type        = bool
  description = "Value to set `self` in `rule_matrix` test rule"
  default     = null
}

variable "inline_rules_enabled" {
  type        = bool
  description = "Value to set true to test inline security group rules"
  default     = false
}
