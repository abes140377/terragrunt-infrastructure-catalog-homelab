include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Dependencies - ensure DNS runs after VM or LXC is created
dependencies {
  paths = compact([
    try(values.lxc_unit_path, null),
    try(values.vm_unit_path, null)
  ])
}

# Generate DNS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "dns_key_secret" {
  description = "TSIG key secret for DNS authentication"
  type        = string
  sensitive   = true
}

provider "dns" {
  update {
    server        = "${values.dns_server}"
    port          = ${try(values.dns_port, 53)}
    key_name      = "${values.key_name}"
    key_algorithm = "${values.key_algorithm}"
    key_secret    = var.dns_key_secret
  }
}
EOF
}

terraform {
  // NOTE: Take note that this source here uses a Git URL instead of a local path.
  //
  // This is because units and stacks are generated
  // as shallow directories when consumed.
  //
  // Assume that a user consuming this unit will exclusively have access
  // to the directory this file is in, and nothing else in this repository.
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/dns?ref=${values.version}"
}

dependency "proxmox_lxc" {
  config_path = coalesce(try(values.lxc_unit_path, null), "../__dummy_lxc__")

  mock_outputs = {
    ipv4 = "192.168.1.100"
  }

  skip_outputs = try(values.lxc_unit_path, null) == null
}

dependency "proxmox_vm" {
  config_path = coalesce(try(values.vm_unit_path, null), "../__dummy_vm__")

  mock_outputs = {
    ipv4 = "192.168.1.101"
  }

  skip_outputs = try(values.vm_unit_path, null) == null
}

inputs = {
  # Required inputs
  zone      = values.zone
  name      = values.name
  addresses = try(
    [dependency.proxmox_lxc.outputs.ipv4],
    [dependency.proxmox_vm.outputs.ipv4],
    values.addresses,
    []
  )

  # Optional inputs
  ttl = try(values.ttl, 300)
}
