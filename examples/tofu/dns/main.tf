terraform {
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = ">= 3.4.0"
    }
  }
  required_version = ">= 1.9.0"
}

provider "dns" {
  update {
    server        = "192.168.1.13"
    port          = 5353
    key_name      = "ddnskey."
    key_algorithm = "hmac-sha512"
    key_secret    = var.dns_key_secret
  }
}

variable "dns_key_secret" {
  description = "The DNS key secret."
  type        = string
}

# Example 1: Regular DNS record only (default behavior)
module "dns_regular" {
  source = "../../../modules/dns"

  env       = "dev"
  app       = "test"
  zone      = "home.sflab.io."
  addresses = ["192.168.1.88"]
  # record_types uses default: { normal = true, wildcard = false }
  # Creates: dev-test.home.sflab.io
}

# Example 2: Wildcard DNS record only
module "dns_wildcard" {
  source = "../../../modules/dns"

  env       = "dev"
  app       = "wildcard"
  zone      = "home.sflab.io."
  addresses = ["192.168.1.99"]
  record_types = {
    normal   = false
    wildcard = true
  }
  # Creates: *.dev-wildcard.home.sflab.io
}

# Example 3: Both regular and wildcard DNS records
module "dns_both" {
  source = "../../../modules/dns"

  env       = "dev"
  app       = "dual"
  zone      = "home.sflab.io."
  addresses = ["192.168.1.77"]
  record_types = {
    normal   = true
    wildcard = true
  }
  # Creates both:
  #   dev-dual.home.sflab.io
  #   *.dev-dual.home.sflab.io
}

output "regular_fqdn" {
  description = "Regular DNS record FQDN"
  value       = module.dns_regular.fqdn
}

output "wildcard_only_fqdn" {
  description = "Wildcard-only DNS record FQDN"
  value       = module.dns_wildcard.fqdn_wildcard
}

output "both_fqdn_normal" {
  description = "Dual example - normal FQDN"
  value       = module.dns_both.fqdn
}

output "both_fqdn_wildcard" {
  description = "Dual example - wildcard FQDN"
  value       = module.dns_both.fqdn_wildcard
}
