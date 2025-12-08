include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Generate Proxmox provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "homelab" {}
EOF
}

terraform {
  source = "../../../.././/modules/naming"
}

inputs = {
  # Required inputs
  env = "staging"
  app = "web"
}
