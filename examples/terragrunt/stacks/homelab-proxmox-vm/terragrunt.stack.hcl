locals {
  version = "main"

  # pool configuration
  pool_id = "example-stack-pool"

  # VM naming configuration
  env = "dev"
  app = "stack-vm"

  # Optional: Customize VM resources
  # memory = 4096  # Memory in MB (default: 2048)
  # cores  = 4     # CPU cores (default: 2)

  # DNS configuration
  zone = "home.sflab.io."

  # SSH key configuration - use absolute path for stack deployments
  ssh_public_key_path = "${get_repo_root()}/keys/admin_id_ecdsa.pub"
}

unit "proxmox_vm_1" {
  source = "../../../../units/proxmox-vm"

  path = "proxmox-vm-1"

  values = {
    version = local.version

    env     = local.env
    app     = "${local.app}-1"
    pool_id = local.pool_id

    # SSH key path
    ssh_public_key_path = local.ssh_public_key_path

    # Optional: Customize VM resources
    # memory = try(local.memory, 2048)
    # cores  = try(local.cores, 2)
    network_config = {
      type        = "static"
      ip_address  = "192.168.1.33"
      cidr        = 24
      gateway     = "192.168.1.1"
      # dns_servers = ["8.8.8.8", "8.8.4.4"]  # Optional
    }
  }
}

unit "proxmox_vm_2" {
  source = "../../../../units/proxmox-vm"

  path = "proxmox-vm-2"

  values = {
    version = local.version

    env     = local.env
    app     = "${local.app}-2"
    pool_id = local.pool_id

    # SSH key path
    ssh_public_key_path = local.ssh_public_key_path

    # Optional: Customize VM resources
    # memory = try(local.memory, 2048)
    # cores  = try(local.cores, 2)
    network_config = {
      type        = "static"
      ip_address  = "192.168.1.34"
      cidr        = 24
      gateway     = "192.168.1.1"
      # dns_servers = ["8.8.8.8", "8.8.4.4"]  # Optional
    }
  }
}

unit "dns_1" {
  source = "../../../../units/dns"

  path = "dns-1"

  values = {
    version = local.version

    env  = local.env
    app  = "${local.app}-1"
    zone = local.zone

    compute_path = "../proxmox-vm-1"
  }
}

unit "dns_2" {
  source = "../../../../units/dns"

  path = "dns-2"

  values = {
    version = local.version

    env  = local.env
    app  = "${local.app}-2"
    zone = local.zone

    compute_path = "../proxmox-vm-2"
  }
}
