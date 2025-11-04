# Multi-VM Deployment Stack Example
#
# This stack demonstrates deploying multiple VMs with DNS registration.
# Each VM is defined in the vms map below with its configuration.
#
# To customize:
# 1. Add or remove VMs by editing the vms map
# 2. Adjust VM properties (memory, cores, etc.) as needed
# 3. Add or remove corresponding DNS units below
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
#   dig web-server-01.home.sflab.io @192.168.1.13 -p 5353
#   dig web-server-02.home.sflab.io @192.168.1.13 -p 5353
#   dig database-01.home.sflab.io @192.168.1.13 -p 5353

locals {
  pool_id = "example-multi-vm-pool"

  # Define multiple VMs with their configurations
  # Key: unique VM identifier (used in Terraform resource addressing)
  # Value: VM configuration object
  vms = {
    "web01" = {
      vm_name = "web-server-01" # Web server instance 1
      memory  = 4096            # 4GB RAM for web workload
    }
    "web02" = {
      vm_name = "web-server-02" # Web server instance 2
      memory  = 4096            # 4GB RAM for web workload
    }
    "db01" = {
      vm_name = "database-01" # Database server
      memory  = 8192          # 8GB RAM for database workload
    }
  }
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

# Create all VMs defined in the vms map
unit "proxmox_vm" {
  // Using local units with relative paths for testing
  // In production, use: git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=v1.0.0
  source = "./units/proxmox-vm"
  path   = "proxmox-vm"

  values = {
    vms            = local.vms
    pool_id        = local.pool_id
    pool_unit_path = "../proxmox-pool"
  }
}

# DNS unit for web01
unit "dns_web01" {
  // Using local units with relative paths for testing
  // In production, use: git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=v1.0.0
  source = "./units/dns"
  path   = "dns-web01"

  values = {
    name          = local.vms["web01"].vm_name
    vm_identifier = "web01" # Tells DNS unit which VM in the map to get IP from

    # zone          = "home.sflab.io."
    # dns_server    = "192.168.1.13"
    # dns_port      = 5353
    # key_name      = "ddnskey."
    # key_algorithm = "hmac-sha512"

    vm_unit_path  = "../proxmox-vm"
  }
}

# DNS unit for web02
unit "dns_web02" {
  // Using local units with relative paths for testing
  // In production, use: git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=v1.0.0
  source = "./units/dns"
  path   = "dns-web02"

  values = {
    name          = local.vms["web02"].vm_name
    vm_identifier = "web02"

    # zone          = "home.sflab.io."
    # dns_server    = "192.168.1.13"
    # dns_port      = 5353
    # key_name      = "ddnskey."
    # key_algorithm = "hmac-sha512"

    vm_unit_path  = "../proxmox-vm"
  }
}

# DNS unit for db01
unit "dns_db01" {
  // Using local units with relative paths for testing
  // In production, use: git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=v1.0.0
  source = "./units/dns"
  path   = "dns-db01"

  values = {
    name          = local.vms["db01"].vm_name
    vm_identifier = "db01"

    # zone          = "home.sflab.io."
    # dns_server    = "192.168.1.13"
    # dns_port      = 5353
    # key_name      = "ddnskey."
    # key_algorithm = "hmac-sha512"

    vm_unit_path  = "../proxmox-vm"
  }
}
