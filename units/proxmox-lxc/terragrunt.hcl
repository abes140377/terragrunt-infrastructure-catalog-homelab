include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/proxmox-lxc?ref=${values.version}"
}

inputs = {
  # Required inputs
  env                 = values.env
  app                 = values.app
  password            = values.password
  ssh_public_key_path = "${get_repo_root()}/keys/admin_id_ecdsa.pub"

  # Optional inputs
  pool_id = try(values.pool_id, "")
}
