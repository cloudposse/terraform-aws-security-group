output "sg_id" {
  description = "The Security Group ID"
  value       = module.this.enabled ? local.sg_id : null
}
