output "ipv4" {
  description = "The IPv4 address of the VM."
  value       = try(values(proxmox_virtual_environment_vm.this.ipv4_addresses)[0], null)
}
