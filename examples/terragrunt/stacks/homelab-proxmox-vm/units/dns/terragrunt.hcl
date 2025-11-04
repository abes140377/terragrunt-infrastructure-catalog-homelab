include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Generate DNS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "dns_key_secret" {
  description = "TSIG key secret for DNS authentication"
  type        = string
  sensitive   = true
}

provider "dns" {
  update {
    server        = "${values.dns_server}"
    port          = ${try(values.dns_port, 53)}
    key_name      = "${values.key_name}"
    key_algorithm = "${values.key_algorithm}"
    key_secret    = var.dns_key_secret
  }
}
EOF
}

terraform {
  source = "../../../../../.././/modules/dns"
}

dependency "proxmox_vm" {
  config_path = try(values.vm_unit_path, "../proxmox-vm")

  # Mock outputs support both multi-VM and single-VM patterns
  mock_outputs = {
    vms = {
      "mock" = {
        ipv4 = "192.168.1.100"
      }
    }
    ipv4 = "192.168.1.100" # Backwards compatibility with single-VM pattern
  }
}

locals {
  # Extract specific VM IP if vm_identifier is provided (multi-VM pattern)
  # Otherwise, fall back to single-VM pattern (ipv4 output)
  # If neither is available, try using provided addresses value
  vm_ip = try(
    dependency.proxmox_vm.outputs.vms[values.vm_identifier].ipv4,
    dependency.proxmox_vm.outputs.ipv4,
    null
  )
}

inputs = {
  zone      = values.zone
  name      = values.name
  addresses = try(
    [local.vm_ip],
    values.addresses,
    []
  )
  ttl = try(values.ttl, 300)
}
