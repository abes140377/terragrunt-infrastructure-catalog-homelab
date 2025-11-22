terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.69.0"
    }
    homelab = {
      source  = "registry.terraform.io/abes140377/homelab"
      version = "0.1.0"
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

provider "homelab" {}

variable "env" {
  description = "The environment this VM belongs to (e.g., dev, staging, prod)."
  type        = string
}

variable "app" {
  description = "The application this VM belongs to (e.g., web, db, api)."
  type        = string
}

variable "pool_id" {
  description = "The ID of the Proxmox pool to which the virtual machine will be assigned."
  type        = string
  default     = ""
}

module "proxmox_vm" {
  source = "../../../modules/proxmox-vm"

  env     = var.env
  app     = var.app
  pool_id = var.pool_id
}
