# Proposal: Add DNS Management Capability

## Why

The infrastructure catalog currently supports Proxmox resource management (LXC containers, resource pools) but lacks the ability to manage DNS records. As containers are provisioned, their DNS entries must be manually configured on the internal BIND9 DNS server at 192.168.1.13. This creates operational overhead and prevents fully automated infrastructure deployment.

## What Changes

- Add new Terraform module `modules/dns` using the HashiCorp DNS provider (hashicorp/dns)
- Add new Terragrunt unit `units/dns` that wraps the DNS module
- Add example configuration in `examples/terragrunt/units/dns`
- Support managing DNS A records on BIND9 server via RFC 2136 dynamic updates
- Follow existing architecture patterns: module structure (main.tf, variables.tf, outputs.tf, versions.tf)
- Support TSIG authentication using key-based authentication

## Impact

- **Affected specs**: New capability `dns-management` (no existing specs affected)
- **Affected code**:
  - New directory `modules/dns/` with standard module files
  - New directory `units/dns/` with terragrunt.hcl
  - New directory `examples/terragrunt/units/dns/` with example configuration
  - Updates to CLAUDE.md to document DNS module usage
- **External dependencies**:
  - BIND9 DNS server at 192.168.1.13 must support RFC 2136 dynamic updates
  - Requires TSIG key configuration (SOPS-encrypted credentials)
  - New environment variable: `TF_VAR_dns_key_secret` for authentication
- **Migration**: None (new capability, no breaking changes)
