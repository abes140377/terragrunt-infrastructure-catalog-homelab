include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Generate DNS provider block with TSIG configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "dns" {
  update {
    server        = "192.168.1.13"
    port          = 5353
    key_name      = "ddnskey."
    key_algorithm = "hmac-sha512"
    key_secret    = "${get_env("TF_VAR_dns_key_secret", "mock-secret-for-testing")}"
  }
}
EOF
}

terraform {
  // This double-slash allows the module to leverage relative paths to other modules in this repository.
  //
  // NOTE: When used in a different repository, you will need to
  // use a source URL that points to the relevant module in this repository.
  // e.g.
  // source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/dns"

  source = "../../../.././/modules/dns"
}

inputs = {
  zone      = "home.sflab.io."
  name      = "example-dns-record"
  addresses = ["192.168.1.100"]
  ttl       = 300
}
