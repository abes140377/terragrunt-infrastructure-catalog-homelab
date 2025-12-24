terraform {
  required_providers {
    homelab = {
      source  = "registry.terraform.io/abes140377/homelab"
      version = ">= 0.2.0"
    }
  }
}

variable "app" {
  description = "Application name"
  type        = string
}

module "naming_dev" {
  source = "../../../modules/naming"

  env = "dev"
  app = var.app
}

module "naming_prod" {
  source = "../../../modules/naming"

  env = "prod"
  app = var.app
}

output "name_dev" {
  description = "Generated dev name"
  value       = module.naming_dev.generated_name
}

output "name_prod" {
  description = "Generated prod name"
  value       = module.naming_prod.generated_name
}
