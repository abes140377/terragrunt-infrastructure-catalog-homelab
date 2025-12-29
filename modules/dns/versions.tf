terraform {
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = ">= 3.4.0"
    }
    homelab = {
      source  = "registry.terraform.io/sflab-io/homelab"
      version = ">= 0.3.0"
    }
  }
  required_version = ">= 1.9.0"
}
