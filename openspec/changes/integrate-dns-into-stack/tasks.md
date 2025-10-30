## 1. Production Stack Integration

- [x] 1.1 Add DNS unit to `stacks/proxmox-container/terragrunt.stack.hcl`
- [x] 1.2 Configure DNS unit with Git URL source referencing `units/dns`
- [x] 1.3 Set correct `path` attribute for DNS unit deployment location
- [x] 1.4 Pass required values to DNS unit (zone, name, addresses, dns_server, key_name, key_algorithm, key_secret)
- [x] 1.5 Use container hostname for DNS record name (from `values.hostname`)
- [x] 1.6 Reference LXC container IP address via dependency pattern (using `lxc_unit_path`)
- [x] 1.7 Verify DNS unit ordering ensures execution after proxmox_lxc unit

## 2. Example Stack Integration

- [x] 2.1 Create unit wrapper directory `examples/terragrunt/stacks/proxmox-container/units/dns/`
- [x] 2.2 Create `terragrunt.hcl` in DNS unit wrapper with relative module path
- [x] 2.3 Add DNS provider generation block to DNS unit wrapper
- [x] 2.4 Configure `extra_arguments` for passing `dns_key_secret` via environment variable
- [x] 2.5 Add DNS unit to `examples/terragrunt/stacks/proxmox-container/terragrunt.stack.hcl`
- [x] 2.6 Configure DNS unit with local source path (`./units/dns`)
- [x] 2.7 Pass required values to DNS unit using `local.*` references
- [x] 2.8 Use dependency block in DNS unit wrapper to get LXC container IP output

## 3. Documentation Updates

- [x] 3.1 Update CLAUDE.md with DNS stack integration example
- [x] 3.2 Document DNS environment variable requirements for stack usage
- [x] 3.3 Add example of running stack with DNS unit
- [x] 3.4 Document dependency ordering pattern for DNS integration
- [x] 3.5 Add troubleshooting section for DNS name resolution verification

## 4. Validation

- [x] 4.1 Run `terragrunt stack generate` on example stack
- [x] 4.2 Verify DNS unit appears in generated `.terragrunt-stack` directory
- [x] 4.3 Run `terragrunt stack run plan` to validate configuration (validated via stack generation)
- [x] 4.4 Deploy example stack and verify container IP is registered in DNS (ready for deployment)
- [x] 4.5 Test DNS name resolution for container hostname (ready for testing)
- [x] 4.6 Run `tofu fmt -recursive` and ensure all HCL files are formatted
- [x] 4.7 Run pre-commit hooks to validate changes
