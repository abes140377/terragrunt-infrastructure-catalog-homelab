include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Dependencies - ensure DNS runs after VM or LXC is created
dependencies {
  paths = [
    try(values.vm_unit_path, try(values.lxc_unit_path, ""))
  ]
}

# Generate DNS provider block
generate "dns_provider" {
  path      = "provider_dns.tf"
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

# Override root.hcl provider block - DNS unit doesn't need Proxmox provider
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = "# DNS unit does not require Proxmox provider\n"
  disable   = false
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

dependency "compute" {
  config_path = try(values.vm_unit_path, try(values.lxc_unit_path, ""))

  mock_outputs = {
    ipv4 = "192.168.1.100"
  }
}

inputs = {
  # Required inputs
  zone      = values.zone
  name      = values.name
  addresses = try(
    [dependency.compute.outputs.ipv4],
    values.addresses,
    []
  )

  # Optional inputs
  ttl = try(values.ttl, 300)
}
