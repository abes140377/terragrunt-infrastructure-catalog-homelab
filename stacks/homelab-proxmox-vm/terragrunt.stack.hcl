# Multi-VM Deployment Stack
#
# This stack supports deploying multiple VMs with DNS registration.
# Configured via values pattern for external consumption.
#
# Required values:
# - values.version: Git ref for unit sources (e.g., "v1.0.0")
# - values.pool_id: Proxmox resource pool ID
# - values.vms: Map of VM configurations
# - values.dns_zone: DNS zone for records (default: "home.sflab.io.")
# - values.dns_server: DNS server address (default: "192.168.1.13")
# - values.dns_port: DNS server port (default: 5353)
#
# Example values.vms structure:
# vms = {
#   "web01" = {
#     vm_name = "web-server-01"
#     memory  = 4096
#     cores   = 2
#   }
#   "db01" = {
#     vm_name = "database-01"
#     memory  = 8192
#     cores   = 4
#   }
# }
#
# Note: When adding or removing VMs, you must also add or remove
# the corresponding DNS unit blocks below. Dynamic unit generation
# is not supported in Terragrunt stack files.

locals {
  pool_id    = values.pool_id != "" ? values.pool_id : ""
  vms        = values.vms
  dns_zone   = try(values.dns_zone, "home.sflab.io.")
  dns_server = try(values.dns_server, "192.168.1.13")
  dns_port   = try(values.dns_port, 5353)
}

# Create a resource pool for organizing VMs
unit "proxmox_pool" {
  // NOTE: Take note that this source here uses a Git URL instead of a local path.
  //
  // This is because units and stacks are generated
  // as shallow directories when consumed.
  //
  // Assume that a user consuming this stack will exclusively have access
  // to the directory this file is in, and nothing else in this repository.
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=${values.version}"
  path   = "proxmox-pool"

  values = {
    pool_id = values.pool_id
  }
}

# Create all VMs defined in the vms map
unit "proxmox_vm" {
  // NOTE: Take note that this source here uses a Git URL instead of a local path.
  //
  // This is because units and stacks are generated
  // as shallow directories when consumed.
  //
  // Assume that a user consuming this stack will exclusively have access
  // to the directory this file is in, and nothing else in this repository.
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${values.version}"
  path   = "proxmox-vm"

  values = {
    vms            = local.vms
    pool_id        = values.pool_id
    pool_unit_path = "../proxmox-pool"
  }
}

# NOTE: DNS units must be manually defined for each VM
# To add a new VM's DNS record, copy one of the blocks below and update:
# - unit name (e.g., "dns_newvm")
# - path (e.g., "dns-newvm")
# - name (e.g., local.vms["newvm"].vm_name)
# - vm_identifier (e.g., "newvm")
