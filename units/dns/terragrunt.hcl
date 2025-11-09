include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "dns-config" {
  path = find_in_parent_folders("dns-config.hcl")
  expose = true
}

# Generate DNS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "dns" {
  update {
    server        = "${include.dns-config.locals.dns_server}"
    port          = "${include.dns-config.locals.dns_port}"
    key_name      = "${include.dns-config.locals.key_name}"
    key_algorithm = "${include.dns-config.locals.key_algorithm}"
    key_secret    = "${get_env("TF_VAR_dns_key_secret", "mock-secret-for-testing")}"
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
  config_path = values.compute_path

  # Mock outputs support single-VM pattern (both VM and LXC)
  mock_outputs = {
    ipv4 = "192.168.1.100"
  }
}

inputs = {
  # Required inputs
  zone = values.zone
  name = values.name

  # Optional inputs

  # Extract IP from single-VM pattern (ipv4 output)
  # If not available, try using provided addresses value
  addresses = try(
    [dependency.compute.outputs.ipv4],
    values.addresses,
    []
  )

  # Optional inputs
  ttl = try(values.ttl, 300)
}
