include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  provider_vars    = read_terragrunt_config(find_in_parent_folders("provider-config.hcl"))
  proxmox_endpoint = "https://${local.provider_vars.locals.proxmox_host}:${local.provider_vars.locals.proxmox_port}/"
}

# Generate Proxmox provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "proxmox" {
  endpoint  = "${local.proxmox_endpoint}"
  insecure  = true

  ssh {
    agent = true
  }
}
EOF
}

terraform {
  // This double-slash allows the module to leverage relative paths to other modules in this repository.
  //
  // NOTE: When used in a different repository, you will need to
  // use a source URL that points to the relevant module in this repository.
  // e.g.
  // source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/proxmox-vm"

  source = "../../../.././/modules/proxmox-vm"
}

dependency "proxmox_pool" {
  config_path = "../proxmox-pool"

  mock_outputs = {
    pool_id = "mock-pool"
  }
}

inputs = {
  vm_name = "example-terragrunt-units-proxmox-vm"
  pool_id = dependency.proxmox_pool.outputs.pool_id
}
