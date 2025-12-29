include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider_proxmox" {
  path   = find_in_parent_folders("provider-config.hcl")
  # expose = true
}

terraform {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//modules/proxmox-pool?ref=${values.version}"
}

inputs = {
  # Required inputs
  pool_id = values.pool_id

  # Optional inputs
  # billing_mode = try(values.billing_mode, "PAY_PER_REQUEST")
}
