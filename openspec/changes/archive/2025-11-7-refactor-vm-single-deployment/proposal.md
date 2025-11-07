# Refactor proxmox-vm Module to Single VM Deployment

## Why

The current proxmox-vm module uses a for_each pattern to support multiple VMs, which adds unnecessary complexity when users only need to deploy a single VM. This pattern differs from the simpler proxmox-lxc module which deploys a single container. Users must provide a map structure even for single VM deployments, and DNS units require vm_identifier to extract IPs from the map-based outputs.

By refactoring to a single-VM pattern (matching proxmox-lxc), we'll provide a more intuitive interface, reduce configuration complexity, and maintain consistency across the catalog's module architecture.

## What Changes

- **Module refactor**: Convert proxmox-vm module from multi-VM (for_each) to single-VM pattern
  - Replace `vms` map variable with individual `vm_name`, `memory`, `cores`, `pool_id` variables
  - Remove `for_each` from resource declaration
  - Simplify outputs to return single `ipv4`, `vm_id`, `vm_name` values
- **Unit update**: Modify units/proxmox-vm/terragrunt.hcl to use new single-VM inputs pattern
  - Change from `values.vms` map to individual `values.vm_name`, `values.memory`, `values.cores`, `values.pool_id`
- **Stack update**: Simplify stacks/homelab-proxmox-vm/terragrunt.stack.hcl for single VM deployment
  - Remove multi-VM map structure and dns_web01, dns_web02, dns_db01 units
  - Single proxmox_vm unit with single dns unit (no vm_identifier required)
- **Example updates**: Update examples to reflect single-VM pattern
  - examples/terragrunt/units/proxmox-vm/terragrunt.hcl
  - examples/terragrunt/stacks/homelab-proxmox-vm/terragrunt.stack.hcl and unit wrappers
- **DNS unit compatibility**: Update dns unit to work seamlessly with single-VM outputs
  - Maintain backwards compatibility with LXC pattern
  - Remove multi-VM map handling (vms[vm_identifier]) since no longer needed
  - Simplify to use dependency.compute.outputs.ipv4 directly
- **Documentation**: Update CLAUDE.md to reflect single-VM architecture

**BREAKING**: This change breaks the existing multi-VM pattern. Users currently deploying multiple VMs with a single module call will need to create separate module instances for each VM.

## Impact

- **Affected specs**: vm-management
- **Affected code**:
  - `modules/proxmox-vm/main.tf` - Remove for_each, simplify resource
  - `modules/proxmox-vm/variables.tf` - Replace vms map with individual variables
  - `modules/proxmox-vm/outputs.tf` - Return single values instead of map
  - `units/proxmox-vm/terragrunt.hcl` - Update inputs pattern
  - `units/dns/terragrunt.hcl` - Simplify IP extraction logic
  - `stacks/homelab-proxmox-vm/terragrunt.stack.hcl` - Simplify to single VM + DNS
  - `examples/terragrunt/units/proxmox-vm/terragrunt.hcl` - Update example inputs
  - `examples/terragrunt/stacks/homelab-proxmox-vm/*` - Simplify example stack
  - `CLAUDE.md` - Update VM documentation
