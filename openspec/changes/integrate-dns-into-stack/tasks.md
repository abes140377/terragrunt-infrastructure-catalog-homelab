## 1. Production Stack Integration

- [ ] 1.1 Add DNS unit to `stacks/proxmox-container/terragrunt.stack.hcl`
- [ ] 1.2 Configure DNS unit with Git URL source referencing `units/dns`
- [ ] 1.3 Set correct `path` attribute for DNS unit deployment location
- [ ] 1.4 Pass required values to DNS unit (zone, name, addresses, dns_server, key_name, key_algorithm, key_secret)
- [ ] 1.5 Use container hostname for DNS record name (from `values.hostname`)
- [ ] 1.6 Reference LXC container IP address via values pattern (not dependency block)
- [ ] 1.7 Verify DNS unit ordering ensures execution after proxmox_lxc unit

## 2. Example Stack Integration

- [ ] 2.1 Create unit wrapper directory `examples/terragrunt/stacks/proxmox-container/units/dns/`
- [ ] 2.2 Create `terragrunt.hcl` in DNS unit wrapper with relative module path
- [ ] 2.3 Add DNS provider generation block to DNS unit wrapper
- [ ] 2.4 Configure `extra_arguments` for passing `dns_key_secret` via environment variable
- [ ] 2.5 Add DNS unit to `examples/terragrunt/stacks/proxmox-container/terragrunt.stack.hcl`
- [ ] 2.6 Configure DNS unit with local source path (`./units/dns`)
- [ ] 2.7 Pass required values to DNS unit using `local.*` references
- [ ] 2.8 Use dependency block in DNS unit wrapper to get LXC container IP output

## 3. Documentation Updates

- [ ] 3.1 Update CLAUDE.md with DNS stack integration example
- [ ] 3.2 Document DNS environment variable requirements for stack usage
- [ ] 3.3 Add example of running stack with DNS unit
- [ ] 3.4 Document dependency ordering pattern for DNS integration
- [ ] 3.5 Add troubleshooting section for DNS name resolution verification

## 4. Validation

- [ ] 4.1 Run `terragrunt stack generate` on example stack
- [ ] 4.2 Verify DNS unit appears in generated `.terragrunt-stack` directory
- [ ] 4.3 Run `terragrunt stack run plan` to validate configuration
- [ ] 4.4 Deploy example stack and verify container IP is registered in DNS
- [ ] 4.5 Test DNS name resolution for container hostname (e.g., `dig example-stack-container.home.sflab.io`)
- [ ] 4.6 Run `tofu fmt -recursive` and ensure all HCL files are formatted
- [ ] 4.7 Run pre-commit hooks to validate changes
