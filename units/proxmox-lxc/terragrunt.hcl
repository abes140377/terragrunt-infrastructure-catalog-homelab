include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/proxmox-lxc?ref=${values.version}"
}

dependency "proxmox_pool" {
  config_path = try(values.pool_unit_path, "../proxmox-pool")

  mock_outputs = {
    pool_id = "mock-pool"
  }
}

inputs = {
  # Required inputs
  hostname = values.hostname
  password = values.password

  # Optional inputs
  pool_id = try(values.pool_id, "")
}
