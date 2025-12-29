include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider_proxmox" {
  path = find_in_parent_folders("provider-config.hcl")
}

terraform {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//modules/proxmox-vm?ref=${values.version}"
}

inputs = {
  # Required inputs
  env                 = values.env
  app                 = values.app
  ssh_public_key_path = "${get_repo_root()}/keys/admin_id_ecdsa.pub"

  # Optional inputs
  memory  = try(values.memory, 2048)
  cores   = try(values.cores, 2)
  pool_id = try(values.pool_id, "")

  network_config = try(values.network_config, {
    type = "dhcp"
  })
}
