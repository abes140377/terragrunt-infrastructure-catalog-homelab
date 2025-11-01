# DNS unit does not include root.hcl to avoid Proxmox provider conflicts
# Instead, we configure backend and provider manually

locals {
  # Load environment variables for backend configuration
  environment_vars = try(read_terragrunt_config(find_in_parent_folders("environment.hcl")), {})
  environment_name = try(local.environment_vars.locals.environment_name, "unknown")
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

# Configure S3 backend manually (since we don't include root.hcl)
remote_state {
  backend = "s3"

  config = {
    bucket                      = "homelab-terragrunt-tfstates"
    key                         = "${path_relative_to_include()}/tofu.tfstate"
    region                      = "eu-central-1"
    endpoint                    = "http://minio.home.sflab.io:9000"
    skip_credentials_validation = true
    force_path_style            = true
    access_key                  = get_env("AWS_ACCESS_KEY_ID")
    secret_key                  = get_env("AWS_SECRET_ACCESS_KEY")
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
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
