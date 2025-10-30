## Why

The Proxmox container stack currently creates LXC containers with DHCP-assigned IP addresses, but these containers are not automatically registered in DNS. This requires manual DNS configuration after container creation, making the infrastructure less automated and error-prone. By integrating the DNS unit into the stack, container hostnames will be automatically resolvable immediately after stack deployment.

## What Changes

- Integrate the DNS unit into the `homelab-proxmox-container` stack (both production and example stacks)
- Configure the DNS unit to automatically register the LXC container's IP address after container creation
- Ensure proper dependency ordering so DNS registration happens after the container is created
- Use the existing `home.sflab.io.` DNS zone for container name resolution
- Pass DNS credentials via environment variable (`TF_VAR_dns_key_secret`) consistent with standalone DNS unit usage
- Create unit wrapper for DNS in the example stack to enable local testing

## Impact

- **Affected specs:** `stack-dns-integration` (NEW)
- **Affected code:**
  - `stacks/homelab-proxmox-container/terragrunt.stack.hcl` - Add DNS unit to production stack
  - `examples/terragrunt/stacks/homelab-proxmox-container/terragrunt.stack.hcl` - Add DNS unit to example stack
  - `examples/terragrunt/stacks/homelab-proxmox-container/units/dns/` - Create unit wrapper for testing
  - `CLAUDE.md` - Update documentation with DNS stack integration examples
