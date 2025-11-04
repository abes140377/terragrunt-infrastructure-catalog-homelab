# Create VMs using for_each to iterate over the vms map
# Each VM is identified by its map key and can be independently managed
resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.vms

  name      = each.value.vm_name
  node_name = "pve1"
  pool_id   = each.value.pool_id != "" ? each.value.pool_id : null

  clone {
    vm_id = 9002
  }

  agent {
    # NOTE: The agent is installed and enabled as part of the cloud-init configuration in the template VM, see cloud-config.tf
    # The working agent is *required* to retrieve the VM IP addresses.
    # If you are using a different cloud-init configuration, or a different clone source
    # that does not have the qemu-guest-agent installed, you may need to disable the `agent` below and remove the `vm_ipv4_address` output.
    # See https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#qemu-guest-agent for more details.
    enabled = true
  }

  memory {
    dedicated = each.value.memory
  }

  initialization {
    # dns {
    #   servers = ["1.1.1.1"]
    # }
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}
