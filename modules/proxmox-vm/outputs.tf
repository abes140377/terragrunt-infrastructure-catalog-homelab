output "ipv4" {
  description = "The IPv4 address of the virtual machine."
  value       = try(proxmox_virtual_environment_vm.this.ipv4_addresses[1][0], null)
}

output "vm_id" {
  description = "The Proxmox VM ID."
  value       = proxmox_virtual_environment_vm.this.id
}

output "vm_name" {
  description = "The name of the virtual machine."
  value       = proxmox_virtual_environment_vm.this.name
}
