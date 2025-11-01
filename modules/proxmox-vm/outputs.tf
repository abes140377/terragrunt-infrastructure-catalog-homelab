output "ipv4" {
  description = "The IPv4 address of the VM."
  value       = try(proxmox_virtual_environment_vm.this.ipv4_addresses[1][0], null)
}
