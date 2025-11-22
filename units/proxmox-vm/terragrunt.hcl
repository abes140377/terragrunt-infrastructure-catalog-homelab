include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider_proxmox" {
  path = find_in_parent_folders("provider-config.hcl")
}

terraform {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/proxmox-vm?ref=${values.version}"
}

inputs = {
  # Required inputs
  env = values.env
  app = values.app

  # Optional inputs
  memory  = try(values.memory, 2048)
  cores   = try(values.cores, 2)
  pool_id = try(values.pool_id, "")
}
