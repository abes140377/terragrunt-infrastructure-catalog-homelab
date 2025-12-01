locals {
  pool_id = values.pool_id != "" ? values.pool_id : ""

  env    = values.env
  app    = values.app

  memory = try(values.memory, 2048)
  cores  = try(values.cores, 2)

  # SSH public key path for Ansible access
  ssh_public_key_path = try(values.ssh_public_key_path, "./keys/ansible_id_ecdsa.pub")

  # Network configuration (DHCP by default, can override with static IP)
  # Example static IP configuration:
  # network_config = {
  #   type        = "static"
  #   ip_address  = "192.168.1.100"
  #   cidr        = 24
  #   gateway     = "192.168.1.1"
  #   dns_servers = ["8.8.8.8", "8.8.4.4"]  # Optional
  # }
  network_config = try(values.network_config, { type = "dhcp" })

  zone = try(values.dns_zone, "home.sflab.io.")
}

unit "proxmox_pool" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=${values.version}"

  path = "proxmox-pool"

  values = {
    version = values.version

    pool_id = local.pool_id
  }
}

unit "proxmox_vm" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${values.version}"

  path = "proxmox-vm"

  values = {
    version = values.version

    env                 = local.env
    app                 = local.app
    memory              = local.memory
    cores               = local.cores
    pool_id             = local.pool_id
    ssh_public_key_path = local.ssh_public_key_path
    network_config      = local.network_config
  }
}

unit "dns" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${values.version}"

  path = "dns"

  values = {
    version = values.version

    name = "${local.env}-${local.app}"
    zone = local.zone

    compute_path = "../proxmox-vm"
  }
}
