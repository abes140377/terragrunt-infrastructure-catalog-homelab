locals {
  version = "feat/next"

  # pool configuration
  pool_id = "example-stack-pool"

  # Naming configuration
  env = "staging"
  app = "vm"

  # Optional: Customize VM resources
  # memory = 4096  # Memory in MB (default: 2048)
  # cores  = 4     # CPU cores (default: 2)

  # DNS configuration
  zone = "home.sflab.io."
}

unit "naming" {
  source = "../../../../units/naming"

  path = "naming"

  values = {
    version = local.version

    env = local.env
    app = local.app
  }
}

unit "proxmox_vm_1" {
  source = "../../../../units/proxmox-vm"

  path = "proxmox-vm-1"

  values = {
    version = local.version

    # Name follows pattern from naming unit: {env}-{app}-{instance}
    # Naming unit generates base name "staging-vm1", we append instance number
    vm_name = "staging-vm-1"
    pool_id = local.pool_id

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

    # Name follows pattern from naming unit: {env}-{app}-{instance}
    # Naming unit generates base name "staging-vm1", we append instance number
    vm_name = "staging-vm-2"
    pool_id = local.pool_id

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

    # Name follows pattern from naming unit: {env}-{app}-{instance}
    name = "staging-vm-1"
    zone = local.zone

    compute_path = "../proxmox-vm-1"
  }
}

unit "dns_2" {
  source = "../../../../units/dns"

  path = "dns-2"

  values = {
    version = local.version

    # Name follows pattern from naming unit: {env}-{app}-{instance}
    name = "staging-vm-2"
    zone = local.zone

    compute_path = "../proxmox-vm-2"
  }
}
