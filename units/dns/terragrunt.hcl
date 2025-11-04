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

dependency "compute" {
  config_path = try(values.vm_unit_path, try(values.lxc_unit_path, ""))

  # Mock outputs support both multi-VM and single-VM patterns
  mock_outputs = {
    vms = {
      "mock" = {
        ipv4 = "192.168.1.100"
      }
    }
    ipv4 = "192.168.1.100" # Backwards compatibility with single-VM pattern
  }
}

inputs = {
  # Required inputs
  zone = values.zone
  name = values.name
  # Extract specific VM IP if vm_identifier is provided (multi-VM pattern)
  # Otherwise, fall back to single-VM pattern (ipv4 output)
  # If neither is available, try using provided addresses value
  addresses = try(
    [dependency.compute.outputs.vms[values.vm_identifier].ipv4],
    [dependency.compute.outputs.ipv4],
    values.addresses,
    []
  )

  # Optional inputs
  ttl = try(values.ttl, 300)
}
