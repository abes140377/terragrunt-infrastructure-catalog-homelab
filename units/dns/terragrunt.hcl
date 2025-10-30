include "root" {
  path = find_in_parent_folders("root.hcl")
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

inputs = {
  # Required inputs
  zone          = values.zone
  name          = values.name
  addresses     = values.addresses
  dns_server    = values.dns_server
  key_name      = values.key_name
  key_algorithm = values.key_algorithm
  key_secret    = values.key_secret

  # Optional inputs
  ttl = try(values.ttl, 300)
}
