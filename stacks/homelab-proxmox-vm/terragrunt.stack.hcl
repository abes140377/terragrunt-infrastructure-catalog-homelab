# Multi-VM Deployment Stack
#
# This stack supports deploying multiple VMs with DNS registration.
# Configured via values pattern for external consumption.
#
# Required values:
# - values.version: Git ref for unit sources (e.g., "v1.0.0")
# - values.pool_id: Proxmox resource pool ID
# - values.vms: Map of VM configurations
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

locals {
  pool_id = values.pool_id != "" ? values.pool_id : ""
  vms     = values.vms
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

# Create DNS A records for each VM using dynamic unit generation
# This creates one DNS unit per VM with path pattern: dns-{vm_key}
dynamic "unit" {
  for_each = local.vms

  content {
    // NOTE: Take note that this source here uses a Git URL instead of a local path.
    //
    // This is because units and stacks are generated
    // as shallow directories when consumed.
    //
    // Assume that a user consuming this stack will exclusively have access
    // to the directory this file is in, and nothing else in this repository.
    source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${values.version}"
    path   = "dns-${unit.key}" # Unique path per VM

    values = {
      zone          = "home.sflab.io."
      name          = unit.value.vm_name # DNS name matches VM name
      dns_server    = "192.168.1.13"
      dns_port      = 5353
      key_name      = "ddnskey."
      key_algorithm = "hmac-sha512"
      vm_unit_path  = "../proxmox-vm"
      vm_identifier = unit.key # Tells DNS unit which VM in the map to get IP from
    }
  }
}
