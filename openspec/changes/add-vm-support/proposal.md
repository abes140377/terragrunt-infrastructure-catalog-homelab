# Add VM Support Proposal

## Why

The infrastructure catalog currently supports LXC containers for lightweight workloads but lacks support for full virtual machines (VMs) that are required for running operating systems with different kernels, or applications requiring full virtualization. Adding VM support will enable users to provision and manage Proxmox VMs alongside containers using the same three-layer architecture (modules, units, stacks).

## What Changes

- Add new `proxmox-vm` unit in `units/` that wraps the existing `modules/proxmox-vm` module
- Create example configuration in `examples/terragrunt/units/proxmox-vm/` demonstrating standalone VM deployment
- Add new `homelab-proxmox-vm` stack in `stacks/` that composes proxmox-pool, proxmox-vm, and dns units
- Create example stack in `examples/terragrunt/stacks/homelab-proxmox-vm/` with local unit wrappers for testing
- Document VM capabilities in CLAUDE.md including module variables, outputs, and usage patterns

The VM unit will follow the same patterns as the existing `proxmox-lxc` unit:
- Uses `values` pattern for parameterization (values.vm_name, values.pool_id)
- Supports dependency on `proxmox-pool` unit for resource organization
- Uses Git URL source for external consumption
- Includes root.hcl for backend and provider configuration

## Impact

- **Affected specs**: New capability `vm-management` (analogous to existing LXC management)
- **Affected code**:
  - New files: `units/proxmox-vm/terragrunt.hcl`
  - New files: `examples/terragrunt/units/proxmox-vm/terragrunt.hcl`
  - New files: `stacks/homelab-proxmox-vm/terragrunt.stack.hcl`
  - New directory: `examples/terragrunt/stacks/homelab-proxmox-vm/` with unit wrappers
  - Updated file: `CLAUDE.md` (documentation)
- **No breaking changes**: Existing modules, units, and stacks remain unchanged
