include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider_proxmox" {
  path = find_in_parent_folders("provider_proxmox.hcl")
}

terraform {
  // NOTE: Take note that this source here uses a Git URL instead of a local path.
  //
  // This is because units and stacks are generated
  // as shallow directories when consumed.
  //
  // Assume that a user consuming this unit will exclusively have access
  // to the directory this file is in, and nothing else in this repository.
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/proxmox-vm?ref=${values.version}"
}

inputs = {
  # Map of VMs to create
  # If a global pool_id is provided at the unit level, merge it into each VM configuration
  # that doesn't already specify its own pool_id
  vms = try(values.pool_id, "") != "" ? {
    for k, vm in values.vms : k => merge(vm, {
      pool_id = try(vm.pool_id, values.pool_id)
    })
  } : values.vms
}
