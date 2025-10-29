locals {
  s3_backend_vars = read_terragrunt_config(find_in_parent_folders("s3-backend.hcl"))
  provider_vars   = read_terragrunt_config(find_in_parent_folders("provider.hcl"))

  s3_backend_prefix                      = local.s3_backend_vars.locals.prefix

  s3_backend_region                      = local.s3_backend_vars.locals.region
  s3_backend_endpoint                    = local.s3_backend_vars.locals.endpoint
  s3_backend_skip_credentials_validation = local.s3_backend_vars.locals.skip_credentials_validation
  s3_backend_force_path_style            = local.s3_backend_vars.locals.force_path_style
  s3_backend_access_key                  = local.s3_backend_vars.locals.access_key
  s3_backend_secret_key                  = local.s3_backend_vars.locals.secret_key

  proxmox_endpoint = "https://${local.provider_vars.locals.proxmox_host}:${local.provider_vars.locals.proxmox_port}/"
}

# Configure the remote backend
remote_state {
  backend = "s3"

  config = {
    bucket                      = "${local.s3_backend_prefix}-homelab-terragrunt-tfstates"

    key                         = "${path_relative_to_include()}/tofu.tfstate"
    region                      = local.s3_backend_region
    endpoint                    = local.s3_backend_endpoint
    skip_credentials_validation = local.s3_backend_skip_credentials_validation
    force_path_style            = local.s3_backend_force_path_style
    access_key                  = local.s3_backend_access_key
    secret_key                  = local.s3_backend_secret_key
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
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
