locals {
  version = "feat/next"

  # pool configuration
  pool_id = "example-stack-vm-pool"

  # VM configuration
  vm_name = "example-stack-vm"

  # Optional: Customize VM resources
  # memory = 4096  # Memory in MB (default: 2048)
  # cores  = 4     # CPU cores (default: 2)

  # DNS configuration
  zone = "home.sflab.io."
}

unit "proxmox_pool" {
  source = "../../../../units/proxmox-pool"

  path = "proxmox-pool"

  values = {
    version = local.version

    pool_id = local.pool_id
  }
}

unit "proxmox_vm_1" {
  source = "../../../../units/proxmox-vm"

  path = "proxmox-vm-1"

  values = {
    version = local.version

    vm_name = "${local.vm_name}-1"
    pool_id = local.pool_id

    pool_unit_path = "../proxmox-pool"

    # Optional: Customize VM resources
    # memory = try(local.memory, 2048)
    # cores  = try(local.cores, 2)
  }
}

unit "proxmox_vm_2" {
  source = "../../../../units/proxmox-vm"

  path = "proxmox-vm-2"

  values = {
    version = local.version

    vm_name = "${local.vm_name}-2"
    pool_id = local.pool_id

    pool_unit_path = "../proxmox-pool"

    # Optional: Customize VM resources
    # memory = try(local.memory, 2048)
    # cores  = try(local.cores, 2)
  }
}

unit "dns_1" {
  source = "../../../../units/dns"

  path = "dns-1"

  values = {
    version = local.version

    name = local.vm_name
    zone = local.zone

    compute_path = "../proxmox-vm-1"
  }
}

unit "dns_2" {
  source = "../../../../units/dns"

  path = "dns-2"

  values = {
    version = local.version

    name = local.vm_name
    zone = local.zone

    compute_path = "../proxmox-vm-2"
  }
}
