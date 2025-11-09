# Proposal: Integrate Naming Unit in Example Stacks

## Why

Example stacks serve as learning resources and templates for users building their own infrastructure. Currently, the `homelab-proxmox-vm` and `homelab-proxmox-container` stacks use hardcoded names, which doesn't showcase the naming unit's capabilities or promote naming standardization. By integrating the naming unit into these examples, users will:

- See how to implement consistent naming conventions across their infrastructure
- Learn the pattern for integrating naming units with compute resources
- Understand how naming outputs flow to dependent units (VMs, containers, DNS)
- Have a working reference for building their own naming-integrated stacks

This change directly supports the project's goal of providing reusable, well-documented infrastructure components by demonstrating best practices in the examples.

## What Changes

- Add naming unit to `examples/terragrunt/stacks/homelab-proxmox-vm/terragrunt.stack.hcl`:
  - Configure naming unit with `env = "staging"` and `app = "vm1"`
  - Update VM units to consume naming unit output for `vm_name`
  - Update DNS units to use generated names
- Add naming unit to `examples/terragrunt/stacks/homelab-proxmox-container/terragrunt.stack.hcl`:
  - Configure naming unit with `env = "staging"` and `app = "container1"`
  - Update LXC units to consume naming unit output for `hostname`
  - Update DNS units to use generated names
- Resource names will change from hardcoded values to generated values:
  - VM stack: `example-stack-vm-1` → `staging-vm1-1` and `example-stack-vm-2` → `staging-vm1-2`
  - Container stack: `example-stack-container-1` → `staging-container1-1` and `example-stack-container-2` → `staging-container1-2`

**Note**: This only affects example stack configurations. Production stacks in `stacks/` directory are unchanged.

## Problem

The example stacks (`homelab-proxmox-vm` and `homelab-proxmox-container`) currently use hardcoded, static names for VMs and containers. This approach doesn't demonstrate the naming unit's value for standardized resource naming conventions and makes it harder for users to adopt consistent naming patterns across their infrastructure.

## Solution

Integrate the existing `naming` unit into both example stacks to:

1. **Demonstrate naming unit usage**: Show how the naming unit provides standardized, consistent resource names following the `<env>-<app>` pattern
2. **Enable environment-based naming**: Use environment and application inputs to generate appropriate resource names
3. **Simplify configuration**: Replace hardcoded names with generated names from the naming unit
4. **Maintain backward compatibility**: Keep the existing stack structure while enhancing it with naming capabilities

The implementation will add naming units to both `homelab-proxmox-vm` and `homelab-proxmox-container` example stacks, configured with:
- Environment: `staging`
- VM stack application: `vm1`
- Container stack application: `container1`

## Scope

This change affects only the example stack configurations in `examples/terragrunt/stacks/`:
- `homelab-proxmox-vm/terragrunt.stack.hcl`
- `homelab-proxmox-container/terragrunt.stack.hcl`

It does NOT affect:
- The production stacks in `stacks/` directory
- The naming unit itself (`units/naming/`)
- Any module implementations
- Other example configurations

## Impact

**Benefits:**
- Users see practical naming unit usage in working examples
- Demonstrates infrastructure naming best practices
- Provides template for users to build their own naming-integrated stacks
- Shows how to pass naming unit outputs to compute units

**Risks:**
- Minimal: Changes only affect example configurations
- Generated resource names will differ from current hardcoded values
- Existing deployed examples will need to be destroyed and recreated with new names

## Dependencies

- Existing `naming` unit (`units/naming/`)
- Custom homelab provider (already deployed)
- Current example stack structure

## Validation

Success criteria:
1. Both example stacks include naming units
2. Naming units generate expected names:
  - VM stack: `staging-vm1`
  - Container stack: `staging-container1`
3. Compute units (VM/LXC) consume naming unit outputs
4. `terragrunt stack run apply` succeeds for both stacks
5. Resources are created with generated names
6. DNS records match the generated names
