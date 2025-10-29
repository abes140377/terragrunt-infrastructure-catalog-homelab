output "ipv4" {
  description = "The IPv4 address of the LXC container."
  value       = try(values(proxmox_virtual_environment_container.this.ipv4)[0], null)
}
