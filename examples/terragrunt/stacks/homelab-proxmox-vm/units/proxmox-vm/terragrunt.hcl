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
  source = "../../../../../.././/modules/proxmox-vm"
}

dependency "proxmox_pool" {
  config_path = try(values.pool_unit_path, "../proxmox-pool")

  mock_outputs = {
    pool_id = "mock-pool"
  }
  skip_outputs = try(values.pool_id != "", false)
}

inputs = {
  # Map of VMs to create
  # If a global pool_id is provided at the unit level, merge it into each VM configuration
  # that doesn't already specify its own pool_id
  vms = try(values.pool_id, "") != "" ? {
    for k, vm in values.vms : k => merge(vm, {
      pool_id = try(vm.pool_id, values.pool_id)
    })
  } : {
    for k, vm in values.vms : k => merge(vm, {
      pool_id = try(vm.pool_id, dependency.proxmox_pool.outputs.pool_id)
    })
  }
}
