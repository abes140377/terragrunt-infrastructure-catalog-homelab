terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.69.0"
    }
  }
  required_version = ">= 1.9.0"
}

provider "proxmox" {
  endpoint = "https://proxmox.home.sflab.io:8006/"
  insecure = true

  ssh {
    agent = true
  }
}

variable "pool_id" {
  description = "The ID of the Proxmox pool."
  type        = string
}

module "proxmox_pool" {
  source = "../../../modules/proxmox-pool"

  pool_id = var.pool_id
}

output "name" {
  description = "Generated name"
  value       = module.proxmox_pool.pool_id
}
