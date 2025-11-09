terraform {
  required_providers {
    homelab = {
      source = "registry.terraform.io/abes140377/homelab"
    }
  }
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "app" {
  description = "Application name"
  type        = string
}

module "naming" {
  source = "../../../modules/naming"

  env = var.env
  app = var.app
}

output "name" {
  description = "Generated name"
  value       = module.naming.vm_name
}
