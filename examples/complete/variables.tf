variable "region" {
  type = string
}

variable "rules" {
  type = list(any)
}

variable "rule_matrix_self" {
  type        = bool
  description = "Value to set `self` in `rule_matrix` test rule"
  default     = null
}
