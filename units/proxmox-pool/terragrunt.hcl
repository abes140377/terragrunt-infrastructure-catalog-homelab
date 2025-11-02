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
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/proxmox-pool?ref=${values.version}"
}

inputs = {
  # Required inputs
  pool_id = values.pool_id

  # Optional inputs
  # billing_mode = try(values.billing_mode, "PAY_PER_REQUEST")
}
