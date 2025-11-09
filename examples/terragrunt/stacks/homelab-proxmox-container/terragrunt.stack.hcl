locals {
  version = "feat/next"

  # pool configuration
  pool_id = "example-stack-pool"

  # Naming configuration
  env = "staging"
  app = "container"

  # container configuration
  password = "SecurePassword123!"

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

unit "proxmox_lxc_1" {
  source = "../../../../units/proxmox-lxc"

  path = "proxmox-lxc-1"

  values = {
    version = local.version

    # Hostname follows pattern from naming unit: {env}-{app}-{instance}
    # Naming unit generates base name "staging-container", we append instance number
    hostname = "staging-container-1"
    password = local.password
    pool_id  = local.pool_id
  }
}

# unit "proxmox_lxc_2" {
#   source = "../../../../units/proxmox-lxc"

#   path = "proxmox-lxc-2"

#   values = {
#     version = local.version

#     # Hostname follows pattern from naming unit: {env}-{app}-{instance}
#     # Naming unit generates base name "staging-container", we append instance number
#     hostname = "staging-container-2"
#     password = local.password
#     pool_id  = local.pool_id
#   }
# }

unit "dns_1" {
  source = "../../../../units/dns"

  path = "dns-1"

  values = {
    version = local.version

    # Name follows pattern from naming unit: {env}-{app}-{instance}
    name = "staging-container-1"
    zone = local.zone

    compute_path = "../proxmox-lxc-1"
  }
}

# unit "dns_2" {
#   source = "../../../../units/dns"

#   path = "dns-2"

#   values = {
#     version = local.version

#     # Name follows pattern from naming unit: {env}-{app}-{instance}
#     name = "staging-container-2"
#     zone = local.zone

#     compute_path = "../proxmox-lxc-2"
#   }
# }
