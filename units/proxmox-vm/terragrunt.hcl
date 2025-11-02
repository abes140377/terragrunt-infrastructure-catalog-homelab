include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider_proxmox" {
  path = find_in_parent_folders("provider_proxmox.hcl")
}

dependencies {
  paths = [values.pool_unit_path]
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
  # Required inputs
  vm_name = values.vm_name

  # Optional inputs
  pool_id = try(values.pool_id, "")
}
