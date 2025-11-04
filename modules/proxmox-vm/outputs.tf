output "vms" {
  description = <<-EOT
    Map of VM identifiers to their attributes.
    Each entry contains:
    - id: Proxmox VM ID
    - name: VM name
    - ipv4: VM IPv4 address (null if not available)

    Example output:
    {
      "web01" = {
        id   = 100
        name = "web-server-01"
        ipv4 = "192.168.1.50"
      }
      "db01" = {
        id   = 101
        name = "database-01"
        ipv4 = "192.168.1.51"
      }
    }
  EOT
  value = {
    for k, vm in proxmox_virtual_environment_vm.this : k => {
      id   = vm.id
      name = vm.name
      ipv4 = try(vm.ipv4_addresses[1][0], null)
    }
  }
}
