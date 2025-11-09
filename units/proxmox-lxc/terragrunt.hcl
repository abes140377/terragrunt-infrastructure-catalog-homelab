include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/proxmox-lxc?ref=${values.version}"
}

inputs = {
  # Required inputs
  hostname = values.hostname
  password = values.password

  # Optional inputs
  pool_id = try(values.pool_id, "")
}
