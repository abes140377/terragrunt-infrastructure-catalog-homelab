include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider_proxmox" {
  path = find_in_parent_folders("provider-config.hcl")
}

terraform {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/proxmox-vm?ref=${values.version}"
}

# dependency "proxmox_pool" {
#   config_path = try(values.pool_unit_path, "../proxmox-pool")

#   mock_outputs = {
#     pool_id = "mock-pool"
#   }
# }

inputs = {
  # Required inputs
  vm_name = values.vm_name

  # Optional inputs
  memory  = try(values.memory, 2048)
  cores   = try(values.cores, 2)
  pool_id = try(values.pool_id, "")
}
