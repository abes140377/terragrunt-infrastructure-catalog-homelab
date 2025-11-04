# Proposal: Enable Multi-VM Deployment with DNS Resolution

## Overview

Extend the existing VM management capabilities to support deploying multiple VMs with DNS name resolution from a single unified configuration. This enables users to provision multiple VMs with a list-of-maps input pattern while maintaining compatibility with the existing three-layer architecture.

## Why

The current single-VM pattern requires users to duplicate stack configurations for each VM they want to deploy. This creates several problems:

1. **Configuration Duplication**: Each VM needs its own stack instance with nearly identical configuration, violating DRY (Don't Repeat Yourself) principles
2. **Management Overhead**: Adding or removing VMs requires creating or destroying entire stack directories
3. **Operational Complexity**: Deploying multiple related VMs requires multiple Terragrunt commands instead of a single atomic operation
4. **Scalability Issues**: The pattern doesn't scale well for homelab environments where users commonly deploy clusters of similar VMs (e.g., web servers, database nodes)
5. **Error Prone**: Maintaining consistency across multiple duplicate configurations is difficult and prone to mistakes

By implementing multi-VM support, users can:
- Define all related VMs in a single, unified configuration
- Deploy multiple VMs atomically with one command
- Easily add or remove VMs by editing a map structure
- Maintain consistency through shared configuration
- Scale their infrastructure more efficiently

This change directly addresses the user's request to "create multiple VMs with a single unified configuration" and provides a foundation for future enhancements like VM clustering, load balancing, and automated scaling patterns.

## Problem Statement

Currently, the `homelab-proxmox-vm` stack can only deploy a single VM with DNS registration. Users who want to deploy multiple VMs must:
- Create separate stack instances for each VM
- Duplicate configuration across multiple directories
- Manually manage multiple Terragrunt executions

This approach is inefficient, error-prone, and doesn't scale well for homelab environments where multiple similar VMs need to be deployed together.

## Proposed Solution

Extend the existing `proxmox-vm` module and unit to support both single-VM and multi-VM deployment patterns using Terraform's `for_each` meta-argument with a map of VM configurations. The solution will:

1. **Module Enhancement**: Add support for `for_each` in the `proxmox-vm` module to create multiple VM resources from a map input
2. **Unit Enhancement**: Update the `proxmox-vm` unit to accept either single VM values or a map of VM configurations
3. **Stack Enhancement**: Extend the `homelab-proxmox-vm` stack to support multi-VM deployment with automatic DNS registration for each VM
4. **Flexible Input Pattern**: Use a `vms` variable that accepts a map where:
   - Each key is a unique VM identifier
   - Each value is a map of VM-specific properties (name, memory, disk size, etc.)
   - Easy to extend with additional properties without breaking changes

## Design Goals

1. **Generic Approach**: Single implementation that handles both single and multiple VMs
2. **Extensible**: Easy to add new VM properties (memory, CPU cores, disk size, etc.) to the configuration map
3. **No Breaking Changes Required**: New implementation can coexist with current patterns (backwards compatibility not required as stated by user)
4. **Consistent Architecture**: Maintain the three-layer pattern (modules, units, stacks)
5. **DNS Integration**: Automatically create DNS A records for each deployed VM
6. **Resource Pool Support**: Allow grouping all VMs into a single resource pool

## Example Usage

### Multi-VM Configuration

```hcl
# In stack or unit values
vms = {
  "web01" = {
    vm_name = "web-server-01"
    memory  = 4096
  }
  "web02" = {
    vm_name = "web-server-02"
    memory  = 4096
  }
  "db01" = {
    vm_name = "database-01"
    memory  = 8192
  }
}
```

This would create three VMs with DNS records:
- `web-server-01.home.sflab.io` → VM IP
- `web-server-02.home.sflab.io` → VM IP
- `database-01.home.sflab.io` → VM IP

### Single-VM Mode (if desired for simplicity)

```hcl
vms = {
  "default" = {
    vm_name = "single-vm"
  }
}
```

## Benefits

1. **Simplified Management**: Define multiple VMs in a single configuration file
2. **DRY Principle**: Eliminate configuration duplication across multiple stack instances
3. **Atomic Operations**: Deploy, update, or destroy multiple VMs together
4. **Clear Relationships**: All related VMs are defined in one place
5. **Future-Proof**: Easy to add properties like CPU cores, disk configurations, network settings without architectural changes

## Impact Analysis

### Files to Modify

1. **Module Layer**:
   - `modules/proxmox-vm/main.tf`: Add `for_each` support for multiple VM resources
   - `modules/proxmox-vm/variables.tf`: Replace single VM variables with map-based input
   - `modules/proxmox-vm/outputs.tf`: Output map of VM IPs keyed by VM identifier

2. **Unit Layer**:
   - `units/proxmox-vm/terragrunt.hcl`: Update to pass `vms` map to module
   - `units/dns/terragrunt.hcl`: May need minor updates for multi-VM DNS integration pattern

3. **Stack Layer**:
   - `stacks/homelab-proxmox-vm/terragrunt.stack.hcl`: Update to use new multi-VM pattern
   - May need new DNS handling for multiple VMs (one DNS unit per VM, or batched approach)

4. **Example Layer**:
   - `examples/terragrunt/stacks/homelab-proxmox-vm/`: Update example to demonstrate multi-VM usage
   - `examples/terragrunt/units/proxmox-vm/`: Update unit example

### Migration Path

Since backwards compatibility is not required, the new implementation will replace the current single-VM pattern. Existing users will need to:
1. Update their stack configurations to use the new `vms` map format
2. Re-run `terragrunt stack generate` to regenerate with new structure
3. Apply changes (Terraform will handle resource recreation)

## Open Questions

1. **DNS Unit Pattern**: Should we create one DNS unit per VM (dynamic unit generation), or enhance the DNS module to accept multiple records?
   - **Option A**: Generate one DNS unit per VM in the stack (using `for_each` in stack configuration)
   - **Option B**: Enhance DNS module to accept a list of name-address pairs

2. **Default Values**: What default values should we provide for optional VM properties (memory, CPU, disk)?
   - Current default: 2048MB memory
   - Propose: Keep current defaults as baseline

3. **Pool Assignment**: Should each VM go to the same pool, or allow per-VM pool assignment?
   - Propose: Single pool for all VMs (simpler), with option to override per-VM if needed

4. **VM Naming**: Should we enforce any naming conventions or validation?
   - Propose: Allow arbitrary names, but document best practices (lowercase, hyphens, no special chars)

## Success Criteria

1. User can define multiple VMs in a single configuration using a map structure
2. Each VM is deployed with its own DNS A record
3. All VMs can be grouped into a single resource pool
4. Easy to add new VM-specific properties (memory, CPU, etc.) without architectural changes
5. Solution passes all pre-commit validation hooks
6. Documentation clearly explains multi-VM usage patterns

## Related Specifications

- `vm-management`: Will be modified to include multi-VM requirements
- `stack-dns-integration`: Will be modified to support DNS registration for multiple VMs
- `dns-management`: May need updates if DNS module approach is chosen

## Timeline Estimate

- Module updates: 2-3 hours
- Unit updates: 1-2 hours
- Stack updates: 2-3 hours
- Example updates: 1-2 hours
- Documentation: 1-2 hours
- Testing and validation: 2-3 hours
- **Total: 9-15 hours** over 2-3 development sessions
