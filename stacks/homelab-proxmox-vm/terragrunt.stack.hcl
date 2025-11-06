# Single VM Deployment Stack
#
# This stack supports deploying a single VM with DNS registration.
# Configured via values pattern for external consumption.
#
# Required values:
# - values.version: Git ref for unit sources (e.g., "v1.0.0")
# - values.pool_id: Proxmox resource pool ID
# - values.vm_name: Name of the virtual machine
#
# Optional values:
# - values.memory: Memory allocation in MB (default: 2048)
# - values.cores: CPU cores (default: 2)
# - values.dns_zone: DNS zone for records (default: "home.sflab.io.")
# - values.dns_server: DNS server address (default: "192.168.1.13")
# - values.dns_port: DNS server port (default: 5353)

locals {
  pool_id    = values.pool_id
  vm_name    = values.vm_name
  memory     = try(values.memory, 2048)
  cores      = try(values.cores, 2)
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
    pool_id = local.pool_id
  }
}

# Create a single VM
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
    vm_name        = local.vm_name
    memory         = local.memory
    cores          = local.cores
    pool_id        = local.pool_id
    pool_unit_path = "../proxmox-pool"
  }
}

# Register VM IP in DNS
unit "dns" {
  // NOTE: Take note that this source here uses a Git URL instead of a local path.
  //
  // This is because units and stacks are generated
  // as shallow directories when consumed.
  //
  // Assume that a user consuming this stack will exclusively have access
  // to the directory this file is in, and nothing else in this repository.
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${values.version}"
  path   = "dns"

  values = {
    zone          = local.dns_zone
    name          = local.vm_name
    dns_server    = local.dns_server
    dns_port      = local.dns_port
    key_name      = "ddnskey."
    key_algorithm = "hmac-sha512"
    vm_unit_path  = "../proxmox-vm"
  }
}
