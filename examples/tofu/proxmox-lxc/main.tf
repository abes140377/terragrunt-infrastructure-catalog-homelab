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

variable "env" {
  description = "The environment this compute resource belongs to (e.g., staging, prod)."
  type        = string
}

variable "app" {
  description = "The name of the application this compute resource belongs to (e.g., web, db)."
  type        = string
}

variable "pool_id" {
  description = "The ID of the Proxmox pool to which the LXC container will be assigned."
  type        = string
  default     = ""
}

module "proxmox_lxc" {
  source = "../../../modules/proxmox-lxc"

  env      = var.env
  app      = var.app
  password = "StrongPassword!"
  pool_id  = var.pool_id
}
