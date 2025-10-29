locals {
  poolid = values.poolid != "" ? values.poolid : ""
  name = values.name
}

unit "proxmox_pool" {
  // NOTE: Take note that this source here uses a Git URL instead of a local path.
  //
  // This is because units and stacks are generated
  // as shallow directories when consumed.
  //
  // Assume that a user consuming this stack will exclusively have access
  // to the directory this file is in, and nothing else in this repository.
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=${values.version}"

  # path = "service"

  values = {
    poolid = values.poolid
  }
}

unit "proxmox_lxc" {
  // NOTE: Take note that this source here uses a Git URL instead of a local path.
  //
  // This is because units and stacks are generated
  // as shallow directories when consumed.
  //
  // Assume that a user consuming this stack will exclusively have access
  // to the directory this file is in, and nothing else in this repository.
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-lxc?ref=${values.version}"

  # path = "db"

  values = {
    name = values.name
  }
}
