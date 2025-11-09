locals {
  pool_id = "example-stack-vm-pool"

  vm_name = "example-stack-vm"

  # Optional: Customize VM resources
  # memory = 4096  # Memory in MB (default: 2048)
  # cores  = 4     # CPU cores (default: 2)

  zone          = "home.sflab.io."
  dns_server    = "192.168.1.13"
  dns_port      = 5353
  key_name      = "ddnskey."
  key_algorithm = "hmac-sha512"
}

unit "proxmox_pool" {
  source = "../../../../units/proxmox-pool"
  path   = "proxmox-pool"

  values = {
    version = "feat/next"

    pool_id = local.pool_id
  }
}

# Create a single VM
unit "proxmox_vm" {
  source = "../../../../units/proxmox-vm"
  path   = "proxmox-vm"

  values = {
    version = "feat/next"

    vm_name        = local.vm_name
    pool_id        = local.pool_id

    pool_unit_path = "../proxmox-pool"

    # Optional: Customize VM resources
    # memory = try(local.memory, 2048)
    # cores  = try(local.cores, 2)
  }
}

unit "dns" {
  source = "../../../../units/dns"
  path   = "dns"

  values = {
    version = "feat/next"

    name          = local.vm_name
    zone          = local.zone
    dns_server    = local.dns_server
    dns_port      = local.dns_port
    key_name      = local.key_name
    key_algorithm = local.key_algorithm

    compute_path = "../proxmox-vm"
  }
}
