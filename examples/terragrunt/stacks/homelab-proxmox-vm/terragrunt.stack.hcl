# Single VM Deployment Stack Example
#
# This stack demonstrates deploying a single VM with DNS registration.
# Uses local unit wrappers for testing with relative module paths.
#
# Required environment variables:
# - AWS_ACCESS_KEY_ID: MinIO access key for Terragrunt backend
# - AWS_SECRET_ACCESS_KEY: MinIO secret key for Terragrunt backend
# - PROXMOX_VE_API_TOKEN: Proxmox API token (format: username@realm!tokenname=secret)
# - TF_VAR_dns_key_secret: TSIG key secret for DNS updates
#
# Deployment commands:
#   terragrunt stack generate
#   terragrunt stack run apply
#
# Verification (note: DNS server runs on port 5353):
#   dig example-stack-vm.home.sflab.io @192.168.1.13 -p 5353

locals {
  pool_id = "example-vm-pool"
  vm_name = "example-stack-vm"

  # Optional: Customize VM resources
  # memory = 4096  # Memory in MB (default: 2048)
  # cores  = 4     # CPU cores (default: 2)
}

# Create a resource pool for organizing VMs
unit "proxmox_pool" {
  // Using local units with relative paths for testing
  // In production, use: git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=v1.0.0
  source = "./units/proxmox-pool"
  path   = "proxmox-pool"

  values = {
    pool_id = local.pool_id
  }
}

# Create a single VM
unit "proxmox_vm" {
  // Using local units with relative paths for testing
  // In production, use: git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=v1.0.0
  source = "./units/proxmox-vm"
  path   = "proxmox-vm"

  values = {
    vm_name        = local.vm_name
    pool_id        = local.pool_id
    pool_unit_path = "../proxmox-pool"

    # Optional: Customize VM resources
    # memory = try(local.memory, 2048)
    # cores  = try(local.cores, 2)
  }
}

# Register VM IP in DNS
unit "dns" {
  // Using local units with relative paths for testing
  // In production, use: git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=v1.0.0
  source = "./units/dns"
  path   = "dns"

  values = {
    name = local.vm_name

    # DNS configuration
    zone          = "home.sflab.io."
    dns_server    = "192.168.1.13"
    dns_port      = 5353
    key_name      = "ddnskey."
    key_algorithm = "hmac-sha512"

    vm_unit_path = "../proxmox-vm"
  }
}
