# Multi-VM Deployment Stack Example
#
# This stack demonstrates deploying multiple VMs with DNS registration.
# Each VM is defined in the vms map below with its configuration.
#
# To customize:
# 1. Add or remove VMs by editing the vms map
# 2. Adjust VM properties (memory, cores, etc.) as needed
# 3. Each VM automatically gets a DNS A record
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

  # To add a new VM, simply add a new entry to the map above:
  # "app01" = {
  #   vm_name = "app-server-01"
  #   memory  = 2048
  #   cores   = 2  # Optional: defaults to 2 if not specified
  # }
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

# Create DNS A records for each VM using dynamic unit generation
# This creates one DNS unit per VM (dns-web01, dns-web02, dns-db01)
dynamic "unit" {
  for_each = local.vms

  content {
    // Using local units with relative paths for testing
    // In production, use: git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=v1.0.0
    source = "./units/dns"
    path   = "dns-${unit.key}" # Unique path per VM (dns-web01, dns-web02, etc.)

    values = {
      zone          = "home.sflab.io."
      name          = unit.value.vm_name # DNS name matches VM name
      dns_server    = "192.168.1.13"
      dns_port      = 5353
      key_name      = "ddnskey."
      key_algorithm = "hmac-sha512"
      vm_unit_path  = "../proxmox-vm"
      vm_identifier = unit.key # Tells DNS unit which VM in the map to get IP from
    }
  }
}
