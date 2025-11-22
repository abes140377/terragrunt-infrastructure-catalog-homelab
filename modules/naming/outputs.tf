output "generated_name" {
  description = "Generated name following the pattern <env>-<app>"
  value       = data.homelab_naming.this.name
}
