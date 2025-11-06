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

  # Mock outputs support single-VM pattern
  mock_outputs = {
    ipv4 = "192.168.1.100"
  }
}

inputs = {
  zone = values.zone
  name = values.name
  # Extract IP from single-VM pattern (ipv4 output)
  # If not available, try using provided addresses value
  addresses = try(
    [dependency.proxmox_vm.outputs.ipv4],
    values.addresses,
    []
  )
  ttl = try(values.ttl, 300)
}
